import XCTest

final class CalibrationFlowTests: XCTestCase {
    func testTapDragCalibrationReachesReviewAndPractice() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let start = app.buttons["start-calibration"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        for _ in 0..<5 where !start.isHittable { app.swipeUp() }
        start.tap()
        let canvas = app.descendants(matching: .any)["tap-canvas"].firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        for _ in 0..<10 {
            // Input goes through the production gesture recognizer; no injected results.
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        let lane = app.descendants(matching: .any)["drag-canvas"].firstMatch
        XCTAssertTrue(lane.waitForExistence(timeout: 10))
        for _ in 0..<4 {
            lane.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.56))
                .press(forDuration: 0.2, thenDragTo: lane.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.56)))
        }
        XCTAssertTrue(app.staticTexts["Calibration Complete"].waitForExistence(timeout: 10))
        let next = app.buttons["Continue"]
        for _ in 0..<4 where !next.isHittable { app.swipeUp() }
        next.tap()
        XCTAssertFalse(app.staticTexts["Calibration Complete"].exists)
        let evidence = XCTAttachment(screenshot: app.screenshot())
        evidence.name = "After tap and drag calibration"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
