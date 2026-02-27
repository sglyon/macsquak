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
        let runtime = try PythonRuntimeManager.shared.prepareRuntime()

        let maxAttempts = max(1, retries + 1)
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try runWorker(file: file, model: model, runtime: runtime)
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 400_000_000)
                }
            }
        }

        throw lastError ?? NSError(domain: "MacSquak.Transcription", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown transcription error"])
    }

    private func runWorker(file: URL, model: String, runtime: PythonRuntimeManager.RuntimeInfo) throws -> String {
        let p = Process()
        p.executableURL = runtime.pythonPath
        p.arguments = [runtime.scriptPath.path, "--audio", file.path, "--model", model]

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
}
