import Foundation
import AVFoundation

final class AudioRecorderService: NSObject {
    private var recorder: AVAudioRecorder?
    private(set) var lastRecordingURL: URL?

    func start() throws {
        try FileManager.default.createDirectory(at: paths.recordingsDir, withIntermediateDirectories: true)
        let filename = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-") + ".wav"
        let url = paths.recordingsDir.appendingPathComponent(filename)
        lastRecordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.record()
    }

    func stop() throws -> URL {
        recorder?.stop()
        guard let url = lastRecordingURL else { throw NSError(domain: "MacSquak", code: 1) }
        return url
    }
}
