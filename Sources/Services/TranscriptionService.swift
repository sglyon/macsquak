import Foundation

struct WorkerResponse: Codable {
    let ok: Bool
    let text: String?
    let model: String?
    let elapsedSeconds: Double?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, text, model, error
        case elapsedSeconds = "elapsed_seconds"
    }
}

final class TranscriptionService {
    func transcribe(file: URL, model: String, retries: Int = 2) async throws -> String {
        let maxAttempts = max(1, retries + 1)
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try runWorker(file: file, model: model)
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 400_000_000)
                }
            }
        }

        throw lastError ?? NSError(domain: "MacSquak.Transcription", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown transcription error"])
    }

    private func runWorker(file: URL, model: String) throws -> String {
        guard let script = findScriptPath() else {
            throw NSError(domain: "MacSquak.Transcription", code: 100, userInfo: [NSLocalizedDescriptionKey: "transcribe_parakeet.py not found"])
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", script.path, "--audio", file.path, "--model", model]

        let out = Pipe(); let err = Pipe()
        p.standardOutput = out
        p.standardError = err
        try p.run()
        p.waitUntilExit()

        let stdout = out.fileHandleForReading.readDataToEndOfFile()
        let stderr = err.fileHandleForReading.readDataToEndOfFile()

        guard p.terminationStatus == 0 else {
            let msg = String(data: stderr, encoding: .utf8) ?? "worker failed"
            throw NSError(domain: "MacSquak.Transcription", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let decoded: WorkerResponse
        do {
            decoded = try JSONDecoder().decode(WorkerResponse.self, from: stdout)
        } catch {
            let raw = String(data: stdout, encoding: .utf8) ?? "<non-utf8>"
            throw NSError(domain: "MacSquak.Transcription", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid worker JSON: \(raw.prefix(300))"])
        }

        if decoded.ok, let text = decoded.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        throw NSError(domain: "MacSquak.Transcription", code: 102, userInfo: [NSLocalizedDescriptionKey: decoded.error ?? "Worker returned empty transcript"])
    }

    private func findScriptPath() -> URL? {
        if let env = ProcessInfo.processInfo.environment["MACSQUAK_PARAKEET_SCRIPT"] {
            let u = URL(fileURLWithPath: env)
            if FileManager.default.fileExists(atPath: u.path) { return u }
        }

        let candidates = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Scripts/transcribe_parakeet.py"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("../Scripts/transcribe_parakeet.py")
        ]

        for c in candidates where FileManager.default.fileExists(atPath: c.path) {
            return c
        }
        return nil
    }
}
