import AVFoundation
import Speech

/// One dictation: microphone (or a file, in test mode) → Apple's on-device SpeechTranscriber → text.
final class Transcriber {
    private let engine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var input: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<String, Error>?
    private var converter: AVAudioConverter?
    private var analyzerFormat: AVAudioFormat?

    /// Called on the audio thread with a 0...1 loudness value, for the HUD meter.
    var onLevel: ((Float) -> Void)?

    static func makeModule() async throws -> SpeechTranscriber {
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
            throw MurmurError.message("Speech recognition doesn't support \(Locale.current.identifier).")
        }
        let module = SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [], attributeOptions: [])
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            try await request.downloadAndInstall()
        }
        return module
    }

    /// Downloads the on-device speech model if it isn't installed yet.
    static func prepare() async throws {
        _ = try await makeModule()
    }

    func start() async throws {
        try await begin()
        let node = engine.inputNode
        let micFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 2048, format: micFormat) { [weak self] buffer, _ in
            self?.feed(buffer)
        }
        engine.prepare()
        try engine.start()
    }

    /// Stops listening and returns the full transcript.
    func stop() async throws -> String {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        return try await finish()
    }

    /// Test mode: runs an audio file through the same conversion and analyzer path as the microphone.
    func transcribe(file url: URL) async throws -> String {
        let file = try AVAudioFile(forReading: url)
        try await begin()
        while file.framePosition < file.length {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096) else { break }
            try file.read(into: buffer)
            feed(buffer)
        }
        return try await finish()
    }

    private func begin() async throws {
        let module = try await Self.makeModule()
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [module])
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        input = continuation
        converter = nil
        resultsTask = Task {
            var text = ""
            for try await result in module.results where result.isFinal {
                text += String(result.text.characters)
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let analyzer = SpeechAnalyzer(modules: [module])
        self.analyzer = analyzer
        try await analyzer.start(inputSequence: stream)
    }

    private func finish() async throws -> String {
        input?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        let text = try await resultsTask?.value ?? ""
        analyzer = nil
        input = nil
        resultsTask = nil
        return text
    }

    private func feed(_ buffer: AVAudioPCMBuffer) {
        reportLevel(buffer)
        guard let target = analyzerFormat, let input else { return }
        if buffer.format == target {
            input.yield(AnalyzerInput(buffer: buffer))
            return
        }
        if converter == nil || converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: target)
        }
        guard let converter else { return }
        let ratio = target.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return }
        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        if error == nil, out.frameLength > 0 {
            input.yield(AnalyzerInput(buffer: out))
        }
    }

    private func reportLevel(_ buffer: AVAudioPCMBuffer) {
        guard let onLevel, let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += samples[i] * samples[i] }
        let rms = (sum / Float(buffer.frameLength)).squareRoot()
        onLevel(min(1, rms * 12))
    }
}

enum MurmurError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let text) = self { return text }
        return nil
    }
}
