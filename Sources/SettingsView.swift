import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Record hotkey:", name: .toggleRecording)
                Picker("Recording mode", selection: $vm.settings.recordingMode) {
                    ForEach(RecordingMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
            }
            Section("Transcription") {
                TextField("Model", text: $vm.settings.parakeetModel)
                Stepper(value: $vm.settings.transcriptionRetries, in: 0...5) {
                    Text("Retries: \(vm.settings.transcriptionRetries)")
                }
                Toggle("Enable post-processing", isOn: $vm.settings.enablePostProcess)
            }
            Section("Post-process") {
                TextField("Endpoint URL", text: $vm.settings.llmEndpoint)
                TextField("Prompt template", text: $vm.settings.promptTemplate)
                SecureField("API Key (stored in Keychain)", text: $vm.tempAPIKey)
                Button("Save API Key") { vm.saveAPIKey() }
            }

            if let err = vm.lastError {
                Section("Last Error") {
                    Text(err).foregroundStyle(.red)
                    Button("Clear") { vm.clearError() }
                }
            }
        }
        .padding()
        .frame(width: 620)
    }
}
