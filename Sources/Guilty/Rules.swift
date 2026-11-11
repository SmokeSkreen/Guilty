import Foundation

struct BlockedApp: Codable, Identifiable, Equatable {
    var id: String
    var name: String
}

struct FocusState: Codable {
    var apps: [BlockedApp] = [
        .init(id: "com.valvesoftware.steam", name: "Steam"),
        .init(id: "com.epicgames.EpicGamesLauncher", name: "Epic Games"),
        .init(id: "com.roblox.RobloxPlayer", name: "Roblox"),
        .init(id: "com.hnc.Discord", name: "Discord"),
        .init(id: "com.spotify.client", name: "Spotify")
    ]
    // Keep the saved key "domains" so existing blocklists still load.
    var domains = ["youtube", "youtu.be", "twitch", "netflix", "disneyplus", "tiktok", "instagram", "reddit", "facebook", "x.com", "twitter", "steampowered", "roblox", "poki", "crazygames", "fandom"]
    var breakSession: BreakSession?
    var breakReminder: Bool?
    var keywordRulesVersion: Int?
    var deadline: Date?
    var duration: TimeInterval = 25 * 60
    var pausedRemaining: TimeInterval?
    var hasSession: Bool { deadline != nil || pausedRemaining != nil }
    var paused: Bool { pausedRemaining != nil }
    var active: Bool { deadline.map { $0 > Date() } ?? false }
    mutating func start(minutes: Int, now: Date = Date()) {
        duration = Double(min(480, max(1, minutes))) * 60
        deadline = now.addingTimeInterval(duration)
        pausedRemaining = nil
    }
    mutating func finish() { deadline = nil; pausedRemaining = nil }
    func timeLeft(now: Date = Date()) -> TimeInterval {
        max(0, pausedRemaining ?? deadline?.timeIntervalSince(now) ?? 0)
    }
    mutating func pause(now: Date = Date()) {
        guard let deadline, deadline > now else { return }
        pausedRemaining = deadline.timeIntervalSince(now)
        self.deadline = nil
    }
    mutating func resume(now: Date = Date()) {
        guard let pausedRemaining else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
    }
    mutating func reset(now: Date = Date()) {
        guard hasSession else { return }
        if paused { pausedRemaining = duration } else { deadline = now.addingTimeInterval(duration) }
    }
    mutating func startBreak(minutes: Int, now: Date = Date()) {
        if let deadline, deadline <= now { finish() }
        pause(now: now)
        breakSession = BreakSession(minutes: minutes, now: now)
        breakReminder = false
    }
    @discardableResult
    mutating func completeBreakIfNeeded(now: Date = Date()) -> Bool {
        guard let session = breakSession, session.pausedRemaining == nil, session.timeLeft(now: now) <= 0 else { return false }
        breakSession = nil
        breakReminder = true
        return true
    }
    mutating func cancelBreak() { breakSession = nil; breakReminder = false }
    mutating func migrateKeywordRules() {
        guard keywordRulesVersion != 1 else { return }
        domains = Array(Set(domains.compactMap { Self.normalizeKeyword($0) })).sorted()
        if !domains.contains("fandom") { domains.append("fandom") }
        keywordRulesVersion = 1
    }
    func blockedKeyword(for address: String) -> String? {
        let raw = address.lowercased()
        // Check escaped URL characters too, so %66andom also counts as fandom.
        let decoded = (address.removingPercentEncoding ?? address).lowercased()
        return domains.first { !$0.isEmpty && (raw.contains($0.lowercased()) || decoded.contains($0.lowercased())) }
    }
    static func normalizeKeyword(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !trimmed.contains(where: { $0.isWhitespace }), !trimmed.contains("*") else { return nil }
        // Accept pasted site addresses as a quick way to add their name.
        if trimmed.contains(".") {
            guard let url = URL(string: trimmed.contains("://") ? trimmed : "https://" + trimmed),
                  ["https", "http"].contains(url.scheme), let host = url.host else { return nil }
            if host == "youtu.be" || host == "x.com" { return host }
            let labels = host.split(separator: ".").dropLast().filter { $0 != "www" }
            return labels.max(by: { $0.count < $1.count }).map(String.init)
        }
        guard !trimmed.contains("://"), !trimmed.contains("/") else { return nil }
        return trimmed
    }
}

// A pass lives only in memory and ends as soon as the user leaves this visit.
struct VisitPass {
    var processID: Int32?
    var page: String?
    mutating func allow(processID: Int32, page: String?) {
        self.processID = processID
        self.page = page
    }
    mutating func observe(processID: Int32?, page: String? = nil, checkingPage: Bool = false) {
        if self.processID != processID || (checkingPage && self.page != page) { clear() }
    }
    func allows(processID: Int32, page: String? = nil) -> Bool {
        self.processID == processID && self.page == page
    }
    mutating func clear() { processID = nil; page = nil }
}

struct BreakSession: Codable {
    var deadline: Date?
    var pausedRemaining: TimeInterval?
    let duration: TimeInterval
    let requestedDuration: TimeInterval?
    var displayDuration: TimeInterval { requestedDuration ?? duration }
    init(minutes: Int, now: Date = Date()) {
        let selected = Double(min(480, max(1, minutes))) * 60
        requestedDuration = selected
        duration = minutes == 5 ? 330 : selected
        deadline = now.addingTimeInterval(duration)
    }
    var paused: Bool { pausedRemaining != nil }
    func timeLeft(now: Date = Date()) -> TimeInterval {
        max(0, pausedRemaining ?? deadline?.timeIntervalSince(now) ?? 0)
    }
    func displaySecondsLeft(now: Date = Date()) -> Int {
        // Five displayed minutes take 330 real seconds; all other lengths stay 1:1.
        let scaled = timeLeft(now: now) * displayDuration / duration
        return max(0, Int(ceil(scaled - 0.000000001)))
    }
    mutating func togglePause(now: Date = Date()) {
        if let pausedRemaining {
            deadline = now.addingTimeInterval(pausedRemaining)
            self.pausedRemaining = nil
        } else {
            pausedRemaining = timeLeft(now: now)
            deadline = nil
        }
    }
    mutating func reset(now: Date = Date()) {
        if paused { pausedRemaining = duration } else { deadline = now.addingTimeInterval(duration) }
    }
}
