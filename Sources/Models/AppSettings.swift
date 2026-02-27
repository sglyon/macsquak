import Foundation

struct AppSettings: Codable {
    var parakeetModel = "mlx-community/parakeet-tdt-0.6b-v3"
    var enablePostProcess = false
    var llmEndpoint = ""
    var promptTemplate = "Clean this transcript for clarity and punctuation:\n\n{raw_transcript}"

    static let fileName = "settings.json"

    static func load() -> AppSettings {
        let url = paths.settingsURL
        guard let data = try? Data(contentsOf: url),
              let v = try? JSONDecoder().decode(AppSettings.self, from: data) else { return .init() }
        return v
    }

    func save() throws {
        let data = try JSONEncoder().encode(self)
        try FileManager.default.createDirectory(at: paths.baseDir, withIntermediateDirectories: true)
        try data.write(to: paths.settingsURL)
    }
}

enum paths {
    static let baseDir: URL = {
        let appSup = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSup.appendingPathComponent("MacSquak", isDirectory: true)
    }()
    static let recordingsDir = baseDir.appendingPathComponent("recordings", isDirectory: true)
    static let settingsURL = baseDir.appendingPathComponent(AppSettings.fileName)
}
