import XCTest
@testable import Guilty

final class RelaxationTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    func testBreakPausesFocusAndKeepsItsTime() {
        var state = FocusState()
        state.start(minutes: 25, now: now)
        state.startBreak(minutes: 5, now: now.addingTimeInterval(60))
        XCTAssertTrue(state.paused)
        XCTAssertFalse(state.active)
        XCTAssertEqual(state.pausedRemaining, 24 * 60)
        XCTAssertEqual(state.breakSession?.timeLeft(now: now.addingTimeInterval(60)), 300)
        XCTAssertFalse(state.completeBreakIfNeeded(now: now.addingTimeInterval(359)))
        XCTAssertTrue(state.completeBreakIfNeeded(now: now.addingTimeInterval(360)))
        XCTAssertNil(state.breakSession)
        XCTAssertEqual(state.breakReminder, true)
        XCTAssertTrue(state.paused)
        XCTAssertEqual(state.pausedRemaining, 24 * 60)
        XCTAssertFalse(state.completeBreakIfNeeded(now: now.addingTimeInterval(400)))
    }
    func testPauseResetResumeAndCancel() {
        var state = FocusState()
        state.startBreak(minutes: 10, now: now)
        state.breakSession?.togglePause(now: now.addingTimeInterval(60))
        XCTAssertEqual(state.breakSession?.timeLeft(now: now.addingTimeInterval(9999)), 540)
        XCTAssertFalse(state.completeBreakIfNeeded(now: now.addingTimeInterval(9999)))
        state.breakSession?.reset(now: now)
        XCTAssertEqual(state.breakSession?.pausedRemaining, 600)
        state.breakSession?.togglePause(now: now.addingTimeInterval(100))
        XCTAssertEqual(state.breakSession?.deadline, now.addingTimeInterval(700))
        state.cancelBreak()
        XCTAssertNil(state.breakSession)
        XCTAssertEqual(state.breakReminder, false)
        XCTAssertFalse(state.completeBreakIfNeeded(now: now.addingTimeInterval(9999)))
    }
    func testRestoreOverdueBreakAndReminder() throws {
        var state = FocusState()
        state.startBreak(minutes: 1, now: now)
        var restored = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(restored.completeBreakIfNeeded(now: now.addingTimeInterval(3600)))
        restored = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(restored))
        XCTAssertEqual(restored.breakReminder, true)
        restored.startBreak(minutes: 5, now: now)
        XCTAssertEqual(restored.breakReminder, false)
    }
    func testLegacySaveAndExpiredFocus() throws {
        var state = FocusState()
        state.start(minutes: 1, now: now)
        state.startBreak(minutes: 0, now: now.addingTimeInterval(61))
        XCTAssertFalse(state.hasSession)
        XCTAssertEqual(state.breakSession?.duration, 60)
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
        object.removeValue(forKey: "breakSession")
        object.removeValue(forKey: "breakReminder")
        let restored = try JSONDecoder().decode(FocusState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(restored.breakSession)
        XCTAssertNil(restored.breakReminder)
    }
}
