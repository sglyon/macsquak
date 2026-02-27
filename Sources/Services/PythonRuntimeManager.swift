import Foundation

final class PythonRuntimeManager {
    static let shared = PythonRuntimeManager()

    private let fm = FileManager.default
    private let runtimeDir = paths.baseDir.appendingPathComponent("runtime", isDirectory: true)
    private let binDirName = "bin"
    private let scriptName = "transcribe_parakeet.py"
    private let versionFileName = "runtime.version"
    private let runtimeVersion = "1"

    struct RuntimeInfo {
        let pythonPath: URL
        let scriptPath: URL
    }

    func prepareRuntime() throws -> RuntimeInfo {
        try fm.createDirectory(at: runtimeDir, withIntermediateDirectories: true)

        let vfile = runtimeDir.appendingPathComponent(versionFileName)
        let current = (try? String(contentsOf: vfile).trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
        let venvDir = runtimeDir.appendingPathComponent("venv", isDirectory: true)
        let py = venvDir.appendingPathComponent("bin/python")

        let needsBootstrap = current != runtimeVersion || !fm.fileExists(atPath: py.path)
        if needsBootstrap {
            try bootstrapVenv(venvDir: venvDir)
            try runtimeVersion.write(to: vfile, atomically: true, encoding: .utf8)
        }

        let scriptPath = try installWorkerScript()
        return RuntimeInfo(pythonPath: py, scriptPath: scriptPath)
    }

    private func bootstrapVenv(venvDir: URL) throws {
        if fm.fileExists(atPath: venvDir.path) {
            try? fm.removeItem(at: venvDir)
        }

        try run(["uv", "venv", venvDir.path])
        let py = venvDir.appendingPathComponent("bin/python").path
        try run(["uv", "pip", "install", "--python", py, "parakeet-mlx", "imageio-ffmpeg"])
    }

    private func installWorkerScript() throws -> URL {
        let binDir = runtimeDir.appendingPathComponent(binDirName, isDirectory: true)
        try fm.createDirectory(at: binDir, withIntermediateDirectories: true)
        let dest = binDir.appendingPathComponent(scriptName)

        guard let bundled = findBundledScript() else {
            throw NSError(domain: "MacSquak.Runtime", code: 201, userInfo: [NSLocalizedDescriptionKey: "Bundled worker script missing"])
        }

        if fm.fileExists(atPath: dest.path) {
            try? fm.removeItem(at: dest)
        }
        try fm.copyItem(at: bundled, to: dest)
        try run(["/bin/chmod", "+x", dest.path])
        return dest
    }

    private func findBundledScript() -> URL? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "transcribe_parakeet", withExtension: "py") {
            return url
        }
        #endif

        if let url = Bundle.main.url(forResource: "transcribe_parakeet", withExtension: "py") {
            return url
        }

        // Dev fallback (if bundle lookup fails)
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let candidates = [
            cwd.appendingPathComponent("Sources/Resources/transcribe_parakeet.py"),
            cwd.appendingPathComponent("../Sources/Resources/transcribe_parakeet.py")
        ]
        return candidates.first(where: { fm.fileExists(atPath: $0.path) })
    }

    private func run(_ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = args
        let err = Pipe()
        p.standardError = err
        p.standardOutput = Pipe()
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "runtime command failed"
            throw NSError(domain: "MacSquak.Runtime", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}
