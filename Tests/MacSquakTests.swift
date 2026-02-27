import XCTest
@testable import MacSquak

final class MacSquakTests: XCTestCase {
    func testSettingsDefaultModel() {
        let s = AppSettings()
        XCTAssertTrue(s.parakeetModel.contains("parakeet"))
    }
}
