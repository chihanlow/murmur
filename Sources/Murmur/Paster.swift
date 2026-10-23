import AppKit
import ApplicationServices

/// Types text into whichever field has focus, by pasting it and then restoring the clipboard.
enum Paster {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Returns false when Accessibility isn't granted; the text is then left on the clipboard.
    @discardableResult
    static func paste(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        let saved = snapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Clipboard managers skip items marked transient.
        pasteboard.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))

        guard isTrusted else { return false }

        let source = CGEventSource(stateID: .hidSystemState)
        let vKey: CGKeyCode = 9
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: keyDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }

        let changeCount = pasteboard.changeCount
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Leave the clipboard alone if something else wrote to it meanwhile.
            guard pasteboard.changeCount == changeCount else { return }
            restore(saved, to: pasteboard)
        }
        return true
    }

    private static func snapshot(_ pasteboard: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        (pasteboard.pasteboardItems ?? []).map { item in
            var copy: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) { copy[type] = data }
            }
            return copy
        }
    }

    private static func restore(_ saved: [[NSPasteboard.PasteboardType: Data]], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let items = saved.map { entries -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in entries { item.setData(data, forType: type) }
            return item
        }
        if !items.isEmpty { pasteboard.writeObjects(items) }
    }
}
