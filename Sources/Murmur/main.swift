import AppKit

// Test mode: `Murmur --transcribe <audio file>` prints the raw and cleaned transcript, then exits.
let arguments = CommandLine.arguments
if let flag = arguments.firstIndex(of: "--transcribe"), flag + 1 < arguments.count {
    let url = URL(fileURLWithPath: arguments[flag + 1])
    Task {
        do {
            let raw = try await Transcriber().transcribe(file: url)
            print("RAW:     \(raw)")
            if let note = Cleaner.availabilityNote {
                print("CLEANED: (skipped: \(note))")
            } else {
                print("CLEANED: \(try await Cleaner.clean(raw))")
            }
            exit(0)
        } catch {
            print("ERROR: \(error.localizedDescription)")
            exit(1)
        }
    }
    dispatchMain()
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let controller = AppController()
    app.delegate = controller
    app.setActivationPolicy(.accessory)
    app.run()
}
