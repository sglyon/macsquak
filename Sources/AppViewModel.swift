import Foundation
import AppKit
import KeyboardShortcuts

@MainActor
final class AppViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var status = "Ready"
    @Published var settings = AppSettings.load() {
        didSet {
            do {
                try settings.save()
            } catch {
                status = "Failed to save settings: \(error.localizedDescription)"
            }
            configureHotkeyHandlers()
        }
    }
    @Published var tempAPIKey = ""
    @Published var lastError: String?

    private let recorder = AudioRecorderService()
    private let transcriber = TranscriptionService()
    private let clipboard = ClipboardService()
    private let postProcessor = LLMPostProcessor()
    private let inserter = TextInsertionService()

    init() {
        configureHotkeyHandlers()
    }

    private func configureHotkeyHandlers() {
        KeyboardShortcuts.disable(.toggleRecording)

        switch settings.recordingMode {
        case .toggle:
            // onKeyDown is more reliable than onKeyUp for global shortcuts across apps
            KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
                self?.toggleRecording()
            }
        case .hold:
            KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
                self?.startRecordingIfNeeded()
            }
            KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
                self?.stopRecordingIfNeededAndTranscribe()
            }
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
            setError("Recording error: \(error.localizedDescription)")
        }
    }

    private func startRecordingIfNeeded() {
        guard !isRecording else { return }
        do {
            try recorder.start()
            isRecording = true
            status = "Recording... (hold mode)"
        } catch {
            setError("Failed to start recording: \(error.localizedDescription)")
        }
    }

    private func stopRecordingIfNeededAndTranscribe() {
        guard isRecording else { return }
        do {
            let file = try recorder.stop()
            isRecording = false
            status = "Saved audio: \(file.lastPathComponent)"
            Task { await transcribe(file) }
        } catch {
            setError("Failed to stop recording: \(error.localizedDescription)")
        }
    }

    func transcribeLast() {
        guard let file = recorder.lastRecordingURL else {
            setError("No recording found")
            return
        }
        Task { await transcribe(file) }
    }

    private func transcribe(_ file: URL) async {
        status = "Transcribing..."
        do {
            let raw = try await transcriber.transcribe(file: file, model: settings.parakeetModel, retries: settings.transcriptionRetries)
            let finalText: String
            if settings.enablePostProcess {
                finalText = try await postProcessor.process(raw: raw, settings: settings)
            } else {
                finalText = raw
            }
            clipboard.copy(finalText)
            if settings.autoInsertIntoActiveApp {
                let ok = inserter.insert(finalText, mode: settings.insertMode)
                status = ok ? "Transcript copied + inserted" : "Transcript copied (insert failed; check Accessibility permission)"
            } else {
                status = "Transcript copied to clipboard"
            }
            lastError = nil
        } catch {
            setError("Transcription failed (audio kept): \(error.localizedDescription)")
        }
    }

    func saveAPIKey() {
        guard !tempAPIKey.isEmpty else { return }
        do {
            try KeychainService.shared.save(key: "MacSquakLLMKey", value: tempAPIKey)
            tempAPIKey = ""
            status = "API key saved"
        } catch {
            setError("Keychain save failed")
        }
    }

    func clearError() { lastError = nil }

    private func setError(_ message: String) {
        status = message
        lastError = message
        log(message)
    }

    private func log(_ message: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        if let data = line.data(using: .utf8) {
            try? FileManager.default.createDirectory(at: paths.baseDir, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: paths.logsURL.path) {
                if let h = try? FileHandle(forWritingTo: paths.logsURL) {
                    try? h.seekToEnd()
                    try? h.write(contentsOf: data)
                    try? h.close()
                }
            } else {
                try? data.write(to: paths.logsURL)
            }
        }
    }
}
