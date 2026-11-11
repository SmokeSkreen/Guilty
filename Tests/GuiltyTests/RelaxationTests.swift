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
        XCTAssertEqual(state.breakSession?.timeLeft(now: now.addingTimeInterval(60)), 330)
        XCTAssertFalse(state.completeBreakIfNeeded(now: now.addingTimeInterval(389)))
        XCTAssertTrue(state.completeBreakIfNeeded(now: now.addingTimeInterval(390)))
        XCTAssertNil(state.breakSession)
        XCTAssertEqual(state.breakReminder, true)
        XCTAssertTrue(state.paused)
        XCTAssertEqual(state.pausedRemaining, 24 * 60)
        XCTAssertFalse(state.completeBreakIfNeeded(now: now.addingTimeInterval(400)))
    }
    func testOnlyFiveMinuteBreakRunsSlowly() {
        let session = BreakSession(minutes: 5, now: now)
        XCTAssertEqual(session.duration, 330)
        XCTAssertEqual(session.displaySecondsLeft(now: now), 300)
        XCTAssertEqual(session.displaySecondsLeft(now: now.addingTimeInterval(1)), 300)
        XCTAssertEqual(session.displaySecondsLeft(now: now.addingTimeInterval(1.1)), 299)
        XCTAssertEqual(session.displaySecondsLeft(now: now.addingTimeInterval(165)), 150)
        XCTAssertEqual(session.displaySecondsLeft(now: now.addingTimeInterval(329)), 1)
        XCTAssertEqual(session.displaySecondsLeft(now: now.addingTimeInterval(330)), 0)
        for minutes in [1, 4, 6, 10, 15, 30, 480] {
            let normal = BreakSession(minutes: minutes, now: now)
            XCTAssertEqual(normal.duration, Double(minutes * 60))
            XCTAssertEqual(normal.displaySecondsLeft(now: now.addingTimeInterval(30)), minutes * 60 - 30)
        }
        var focus = FocusState()
        focus.start(minutes: 5, now: now)
        XCTAssertEqual(focus.duration, 300)
    }
    func testSlowBreakSurvivesPauseResetAndReload() throws {
        var session = BreakSession(minutes: 5, now: now)
        session.togglePause(now: now.addingTimeInterval(165))
        XCTAssertEqual(session.displaySecondsLeft(now: now.addingTimeInterval(900)), 150)
        session = try JSONDecoder().decode(BreakSession.self, from: JSONEncoder().encode(session))
        XCTAssertEqual(session.displaySecondsLeft(now: now), 150)
        session.togglePause(now: now.addingTimeInterval(1000))
        XCTAssertEqual(session.deadline, now.addingTimeInterval(1165))
        session.reset(now: now)
        XCTAssertEqual(session.deadline, now.addingTimeInterval(330))
        XCTAssertEqual(session.displaySecondsLeft(now: now), 300)
        session.togglePause(now: now.addingTimeInterval(10))
        session.reset(now: now)
        XCTAssertEqual(session.pausedRemaining, 330)
        XCTAssertEqual(session.displaySecondsLeft(now: now), 300)
    }
    func testExistingBreakKeepsItsOriginalTiming() throws {
        let old = BreakSession(minutes: 5, now: now)
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as! [String: Any]
        object.removeValue(forKey: "requestedDuration")
        object["duration"] = 300
        let decoded = try JSONDecoder().decode(BreakSession.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.displayDuration, 300)
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
