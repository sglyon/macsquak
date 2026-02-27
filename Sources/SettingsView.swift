import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Toggle Recording:", name: .toggleRecording)
            }
            Section("Transcription") {
                TextField("Model", text: $vm.settings.parakeetModel)
                Toggle("Enable post-processing", isOn: $vm.settings.enablePostProcess)
            }
            Section("Post-process") {
                TextField("Endpoint URL", text: $vm.settings.llmEndpoint)
                TextField("Prompt template", text: $vm.settings.promptTemplate)
                SecureField("API Key (stored in Keychain)", text: $vm.tempAPIKey)
                Button("Save API Key") { vm.saveAPIKey() }
            }
        }
        .padding()
        .frame(width: 560)
    }
}
