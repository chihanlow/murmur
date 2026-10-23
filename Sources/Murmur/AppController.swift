import AppKit
import AVFoundation
import Carbon.HIToolbox
import ServiceManagement

@MainActor
final class AppController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum State { case idle, recording, processing }

    private var state: State = .idle
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let hud = HUD()
    private var transcriber: Transcriber?
    private var hotKey: HotKey?

    private let cleanupKey = "cleanupEnabled"
    private var cleanupEnabled: Bool {
        get { UserDefaults.standard.object(forKey: cleanupKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: cleanupKey) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Cleaner.ensureRulesFile()
        updateIcon()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        hotKey = HotKey(keyCode: kVK_Space, modifiers: optionKey) { [weak self] in
            Task { @MainActor in self?.toggle() }
        }

        AVCaptureDevice.requestAccess(for: .audio) { _ in }
        if !Paster.isTrusted { Paster.requestTrust() }
        Task { try? await Transcriber.prepare() }
    }

    // MARK: Dictation

    private func toggle() {
        switch state {
        case .idle: startDictation()
        case .recording: stopDictation()
        case .processing: NSSound.beep()
        }
    }

    private func startDictation() {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            alert("Murmur needs the microphone", "Allow it in System Settings › Privacy & Security › Microphone.",
                  settings: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
            return
        }
        let transcriber = Transcriber()
        transcriber.onLevel = { [weak self] level in
            DispatchQueue.main.async { self?.hud.push(level: level) }
        }
        self.transcriber = transcriber
        state = .recording
        updateIcon()
        hud.show(.listening)
        NSSound(named: "Tink")?.play()

        Task {
            do {
                try await transcriber.start()
            } catch {
                fail(error)
            }
        }
    }

    private func stopDictation() {
        guard let transcriber else { return }
        state = .processing
        updateIcon()
        hud.show(.transcribing)
        NSSound(named: "Pop")?.play()

        Task {
            do {
                var text = try await transcriber.stop()
                if cleanupEnabled, !text.isEmpty, Cleaner.availabilityNote == nil {
                    hud.show(.cleaning)
                    text = (try? await Cleaner.clean(text)) ?? text
                } else {
                    text = Cleaner.applyReplacements(text, Cleaner.loadRules().replacements)
                }
                finish(text)
            } catch {
                fail(error)
            }
        }
    }

    private func finish(_ text: String) {
        reset()
        guard !text.isEmpty else { return }
        if !Paster.paste(text) {
            alert("Text copied to the clipboard",
                  "To paste it for you, Murmur needs Accessibility access in System Settings › Privacy & Security › Accessibility. Then press ⌘V.",
                  settings: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        }
    }

    private func fail(_ error: Error) {
        transcriber = nil
        reset()
        alert("Dictation failed", error.localizedDescription)
    }

    private func reset() {
        transcriber = nil
        state = .idle
        updateIcon()
        hud.hide()
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let title = state == .recording ? "Stop Dictation" : "Start Dictation"
        let dictate = NSMenuItem(title: title, action: #selector(toggleFromMenu), keyEquivalent: " ")
        dictate.keyEquivalentModifierMask = [.option]
        dictate.isEnabled = state != .processing
        menu.addItem(dictate)
        menu.addItem(.separator())

        let cleanup = NSMenuItem(title: "Clean Up with Apple Intelligence", action: #selector(toggleCleanup), keyEquivalent: "")
        cleanup.state = cleanupEnabled ? .on : .off
        menu.addItem(cleanup)
        if let note = Cleaner.availabilityNote {
            let item = NSMenuItem(title: note, action: nil, keyEquivalent: "")
            item.isEnabled = false
            item.indentationLevel = 1
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem(title: "Edit Cleanup Rules…", action: #selector(editRules), keyEquivalent: ""))
        menu.addItem(.separator())

        if !Paster.isTrusted {
            menu.addItem(NSMenuItem(title: "Allow Auto-Paste (Accessibility)…", action: #selector(openAccessibility), keyEquivalent: ""))
        }
        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Murmur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.action != nil && item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }
    }

    @objc private func toggleFromMenu() { toggle() }
    @objc private func toggleCleanup() { cleanupEnabled.toggle() }
    @objc private func editRules() {
        Cleaner.ensureRulesFile()
        NSWorkspace.shared.open(Cleaner.rulesURL)
    }
    @objc private func openAccessibility() {
        Paster.requestTrust()
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }
    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            alert("Couldn't change Open at Login", error.localizedDescription)
        }
    }

    // MARK: Helpers

    private func updateIcon() {
        let name: String
        switch state {
        case .idle: name = "waveform"
        case .recording: name = "waveform.circle.fill"
        case .processing: name = "ellipsis.circle"
        }
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Murmur")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    private func alert(_ title: String, _ message: String, settings: String? = nil) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        if settings != nil {
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Not Now")
        }
        if alert.runModal() == .alertFirstButtonReturn, let settings { open(settings) }
    }

    private func open(_ url: String) {
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
}
