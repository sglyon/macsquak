import Foundation

final class TranscriptionService {
    func transcribe(file: URL, model: String) async throws -> String {
        let script = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Scripts/transcribe_parakeet.py")

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", script.path, "--audio", file.path, "--model", model]

        let out = Pipe(); let err = Pipe()
        p.standardOutput = out; p.standardError = err
        try p.run()
        p.waitUntilExit()

        let data = out.fileHandleForReading.readDataToEndOfFile()
        let errData = err.fileHandleForReading.readDataToEndOfFile()

        guard p.terminationStatus == 0 else {
            let msg = String(data: errData, encoding: .utf8) ?? "unknown error"
            throw NSError(domain: "MacSquak.Transcription", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let text = obj?["text"] as? String else {
            throw NSError(domain: "MacSquak.Transcription", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid worker JSON"])
        }
        return text
    }
}
