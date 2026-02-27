import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.r, modifiers: [.command, .shift]))
}

@main
struct MacSquakApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        MenuBarExtra("MacSquak", systemImage: vm.isRecording ? "waveform.circle.fill" : "waveform.circle") {
            VStack(alignment: .leading, spacing: 10) {
                Text(vm.status).font(.caption)
                Button(vm.isRecording ? "Stop Recording" : "Start Recording") {
                    vm.toggleRecording()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Transcribe Last Recording") { vm.transcribeLast() }
                Divider()
                if #available(macOS 14.0, *) {
                    SettingsLink()
                } else {
                    Button("Settings") {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .padding()
            .frame(width: 300)
        }

        Settings {
            SettingsView(vm: vm)
        }
    }
}
