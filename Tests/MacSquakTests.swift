import XCTest
@testable import MacSquak

final class MacSquakTests: XCTestCase {
    func testSettingsDefaultModel() {
        let s = AppSettings()
        XCTAssertTrue(s.parakeetModel.contains("parakeet"))
    }

    func testWorkerResponseDecode() throws {
        let json = """
        {"ok":true,"text":"hello","model":"m","elapsed_seconds":0.42,"error":null}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WorkerResponse.self, from: json)
        XCTAssertTrue(decoded.ok)
        XCTAssertEqual(decoded.text, "hello")
        XCTAssertEqual(decoded.model, "m")
        XCTAssertEqual(decoded.elapsedSeconds, 0.42)
    }
}
