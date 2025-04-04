import XCTest
@testable import BlueEmojiTracker

final class BlueEmojiTrackerTests: XCTestCase {
    func testConfigDefaults() {
        // Проверяем значения по умолчанию
        XCTAssertEqual(Config.appVersion, "3.5")
        XCTAssertEqual(Config.blueMinValue, 180)
        XCTAssertEqual(Config.redMaxValue, 100)
        XCTAssertEqual(Config.greenMaxValue, 120)
        XCTAssertEqual(Config.movementThreshold, 5.0)
        XCTAssertEqual(Config.smoothingFactor, 0.5)
        XCTAssertEqual(Config.scanStep, 4)
        XCTAssertEqual(Config.minBluePixels, 10)
        XCTAssertTrue(Config.showHighlight)
        XCTAssertTrue(Config.useMotionPrediction)
    }
    
    func testWindowManagerGetActiveWindows() {
        // Проверка, что метод возвращает непустой список окон
        let windows = WindowManager.getActiveWindows()
        XCTAssertFalse(windows.isEmpty)
    }

    static var allTests = [
        ("testConfigDefaults", testConfigDefaults),
        ("testWindowManagerGetActiveWindows", testWindowManagerGetActiveWindows),
    ]
} 