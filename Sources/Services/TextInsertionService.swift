import Foundation
import AppKit
import ApplicationServices

enum InsertMode: String, Codable, CaseIterable, Identifiable {
    case paste
    case type

    var id: String { rawValue }
    var label: String {
        switch self {
        case .paste: return "Paste (Cmd+V)"
        case .type: return "Type keystrokes"
        }
    }
}

final class TextInsertionService {
    func insert(_ text: String, mode: InsertMode) -> Bool {
        switch mode {
        case .paste:
            return pasteFromClipboard()
        case .type:
            return typeText(text)
        }
    }

    private func pasteFromClipboard() -> Bool {
        guard trustedAX() else { return false }
        guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true), // v
              let up = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false) else {
            return false
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }

    private func typeText(_ text: String) -> Bool {
        guard trustedAX() else { return false }
        guard let src = CGEventSource(stateID: .hidSystemState) else { return false }
        for scalar in text.unicodeScalars {
            var utf16 = Array(String(scalar).utf16)
            guard let down = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false) else { return false }
            down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
        return true
    }

    private func trustedAX() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
}
