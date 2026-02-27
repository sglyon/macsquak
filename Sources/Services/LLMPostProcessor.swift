import Foundation

final class LLMPostProcessor {
    func process(raw: String, settings: AppSettings) async throws -> String {
        guard !settings.llmEndpoint.isEmpty else { return raw }
        let key = try KeychainService.shared.get(key: "MacSquakLLMKey")
        let prompt = settings.promptTemplate.replacingOccurrences(of: "{raw_transcript}", with: raw)

        var req = URLRequest(url: URL(string: settings.llmEndpoint)!)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": prompt])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode ?? 500 < 300 else {
            return raw
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return (obj?["text"] as? String) ?? raw
    }
}
