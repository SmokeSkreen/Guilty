import XCTest
@testable import Guilty

final class RulesTests: XCTestCase {
    func testKeywordsAnywhereInURL() {
        let state = FocusState()
        for url in ["https://m.youtube.com/watch?v=123", "https://notyoutube.org", "https://example.org/youtube", "https://search.example/?q=YouTube", "https://example.org/#youtube"] {
            XCTAssertEqual(state.blockedKeyword(for: url), "youtube")
        }
        for url in ["https://fandom.net", "https://myfandom.org", "https://example.org/fandom/wiki", "https://example.org/?q=%66ANDOM"] {
            XCTAssertEqual(state.blockedKeyword(for: url), "fandom")
        }
        XCTAssertEqual(state.blockedKeyword(for: "https://youtu.be/123"), "youtu.be")
        XCTAssertNil(state.blockedKeyword(for: "https://school.org/homework"))
        for word in state.domains {
            XCTAssertEqual(state.blockedKeyword(for: "https://school.org/path/" + word), word)
        }
    }
    func testKeywordMigrationPreservesSessionAndRemovals() {
        var state = FocusState()
        state.domains = ["youtube.com", "store.steampowered.com", "custom.org", "x.com"]
        state.start(minutes: 40)
        let deadline = state.deadline
        state.migrateKeywordRules()
        XCTAssertEqual(Set(state.domains), Set(["youtube", "steampowered", "custom", "x.com", "fandom"]))
        XCTAssertEqual(state.deadline, deadline)
        state.domains.removeAll { $0 == "fandom" }
        state.migrateKeywordRules()
        XCTAssertFalse(state.domains.contains("fandom"))
    }
    func testVisitPassClearsOnLeavingOrChangingPage() {
        var pass = VisitPass()
        pass.allow(processID: 42, page: nil)
        pass.observe(processID: 42)
        XCTAssertTrue(pass.allows(processID: 42))
        pass.observe(processID: 99)
        XCTAssertFalse(pass.allows(processID: 42))
        pass.allow(processID: 42, page: "tab1:https://youtube.com")
        pass.observe(processID: 42, page: "tab1:https://youtube.com", checkingPage: true)
        XCTAssertTrue(pass.allows(processID: 42, page: "tab1:https://youtube.com"))
        pass.observe(processID: 42, page: "tab2:https://youtube.com", checkingPage: true)
        XCTAssertFalse(pass.allows(processID: 42, page: "tab1:https://youtube.com"))
        pass.allow(processID: 42, page: "tab1:https://youtube.com")
        pass.observe(processID: 42, page: "tab1:https://youtube.com/watch?v=1", checkingPage: true)
        XCTAssertFalse(pass.allows(processID: 42, page: "tab1:https://youtube.com"))
    }
    func testPauseResumeResetEnd() throws {
        var state = FocusState()
        let start = Date(timeIntervalSince1970: 100)
        state.start(minutes: 5, now: start)
        state.pause(now: start.addingTimeInterval(60))
        XCTAssertEqual(state.timeLeft(now: start.addingTimeInterval(900)), 240)
        XCTAssertFalse(state.active)
        XCTAssertTrue(state.hasSession)
        let restored = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(restored.paused)
        XCTAssertEqual(restored.pausedRemaining, 240)
        state.resume(now: start.addingTimeInterval(900))
        XCTAssertEqual(state.deadline, start.addingTimeInterval(1140))
        state.reset(now: start.addingTimeInterval(901))
        XCTAssertEqual(state.deadline, start.addingTimeInterval(1201))
        state.pause(now: start.addingTimeInterval(902))
        state.reset()
        XCTAssertEqual(state.pausedRemaining, 300)
        state.finish()
        XCTAssertFalse(state.hasSession)
        XCTAssertFalse(state.paused)
    }
    func testDurationBoundsAndAbsoluteDeadline() {
        var state = FocusState()
        let start = Date(timeIntervalSince1970: 100)
        state.start(minutes: -1, now: start)
        XCTAssertEqual(state.deadline, start.addingTimeInterval(60))
        state.start(minutes: 999, now: start)
        XCTAssertEqual(state.duration, 480 * 60)
        XCTAssertFalse(state.active)
    }
    func testNormalization() {
        XCTAssertEqual(FocusState.normalizeKeyword(" HTTPS://www.YouTube.com/watch?v=1 "), "youtube")
        XCTAssertEqual(FocusState.normalizeKeyword("twitch.tv"), "twitch")
        XCTAssertEqual(FocusState.normalizeKeyword(" FANDOM "), "fandom")
        XCTAssertNil(FocusState.normalizeKeyword(""))
        XCTAssertNil(FocusState.normalizeKeyword("this is not a site"))
        XCTAssertNil(FocusState.normalizeKeyword("file:///tmp/file"))
    }
    func testLegacySessionIgnoresExceptions() throws {
        let state = FocusState()
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
        object["exceptions"] = ["site:youtube.com"]
        let restored = try JSONDecoder().decode(FocusState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(restored.blockedKeyword(for: "https://youtube.com"), "youtube")
    }
    func testSessionRoundTrip() throws {
        var state = FocusState()
        state.start(minutes: 45)
        let restored = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.deadline, state.deadline)
        XCTAssertEqual(restored.apps, state.apps)
    }
}
