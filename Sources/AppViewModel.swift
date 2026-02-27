import Foundation
import AppKit
import KeyboardShortcuts

@MainActor
final class AppViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var status = "Ready"
    @Published var settings = AppSettings.load()
    @Published var tempAPIKey = ""

    private let recorder = AudioRecorderService()
    private let transcriber = TranscriptionService()
    private let clipboard = ClipboardService()
    private let postProcessor = LLMPostProcessor()

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            self?.toggleRecording()
        }
    }

    func toggleRecording() {
        do {
            if isRecording {
                let file = try recorder.stop()
                isRecording = false
                status = "Saved audio: \(file.lastPathComponent)"
                Task { await transcribe(file) }
            } else {
                try recorder.start()
                isRecording = true
                status = "Recording..."
            }
        } catch {
            status = "Recording error: \(error.localizedDescription)"
        }
    }

    func transcribeLast() {
        guard let file = recorder.lastRecordingURL else {
            status = "No recording found"
            return
        }
        Task { await transcribe(file) }
    }

    private func transcribe(_ file: URL) async {
        status = "Transcribing..."
        do {
            let raw = try await transcriber.transcribe(file: file, model: settings.parakeetModel)
            let finalText: String
            if settings.enablePostProcess {
                finalText = try await postProcessor.process(raw: raw, settings: settings)
            } else {
                finalText = raw
            }
            clipboard.copy(finalText)
            status = "Transcript copied to clipboard"
        } catch {
            status = "Transcription failed (audio kept): \(error.localizedDescription)"
        }
    }

    func saveAPIKey() {
        guard !tempAPIKey.isEmpty else { return }
        do {
            try KeychainService.shared.save(key: "MacSquakLLMKey", value: tempAPIKey)
            tempAPIKey = ""
            status = "API key saved"
        } catch {
            status = "Keychain save failed"
        }
    }
}
