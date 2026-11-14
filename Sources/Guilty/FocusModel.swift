import AppKit
import SwiftUI

struct Accusation {
    let key: String
    let name: String
    let app: NSRunningApplication
    var page: String? = nil
}

@MainActor
final class FocusModel: ObservableObject {
    @Published var state: FocusState
    @Published var remaining = 0
    @Published var breakRemaining = 0
    @Published var accusation: Accusation?
    @Published var browserStatus = "Browser checks begin when you open a supported browser."
    @Published var notice = ""
    @Published private(set) var completedFocus = false
    @Published private(set) var showFocusCompletion = false
    private var timer: Timer?
    private var checking = false
    private let aiReminder = AIUseReminder()
    private var nextReminderBrowserCheck = Date.distantPast
    private var visitPass = VisitPass()
    private var activationObserver: NSObjectProtocol?
    private var activationGeneration = 0
    private let storage: URL
    private let browsers = ["com.apple.Safari", "com.google.Chrome", "com.microsoft.edgemac", "com.brave.Browser", "com.vivaldi.Vivaldi", "com.operasoftware.Opera"]

    init() {
        storage = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Guilty/session.json")
        state = (try? Data(contentsOf: storage)).flatMap { try? JSONDecoder().decode(FocusState.self, from: $0) } ?? FocusState()
        state.migrateKeywordRules()
        if !state.active && !state.paused { state.finish() }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                self?.activationGeneration += 1
                self?.visitPass.observe(processID: app?.processIdentifier)
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        save(); tick()
    }
    var catMood: CourtroomCat.Mood {
        if accusation != nil { return .judging }
        if state.breakReminder == true { return .calling }
        if hasBreak { return .sleeping }
        if completedFocus { return .celebrating }
        return active ? .watching : .idle
    }
    var catCaption: String {
        switch catMood {
        case .judging: return "Really? The court saw that."
        case .calling: return "Recess is over. Back to it!"
        case .sleeping: return "Court adjourned. Nap time."
        case .celebrating: return "Case closed. You did it!"
        case .watching: return "The court is watching you."
        case .idle: return paused ? "Take a breath. I’ll wait." : "Ready when you are."
        }
    }
    var active: Bool { state.active && state.breakSession == nil }
    var hasBreak: Bool { state.breakSession != nil }
    var breakClock: String { String(format: "%02d:%02d", breakRemaining / 60, breakRemaining % 60) }
    var hasSession: Bool { state.hasSession }
    var paused: Bool { state.paused }
    var clock: String { String(format: "%02d:%02d", remaining / 60, remaining % 60) }
    func save() {
        do {
            try FileManager.default.createDirectory(at: storage.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: storage, options: .atomic)
        } catch { notice = "Could not save this session: \(error.localizedDescription)" }
    }
    func start(_ minutes: Int) { completedFocus = false; showFocusCompletion = false; state.cancelBreak(); visitPass.clear(); state.start(minutes: minutes); notice = ""; save(); tick() }
    func pauseOrResume() {
        if paused { state.cancelBreak(); state.resume() } else { state.pause() }
        accusation = nil; visitPass.clear(); save(); tick()
    }
    func reset() { state.reset(); accusation = nil; visitPass.clear(); save(); tick() }
    func end() { completedFocus = false; showFocusCompletion = false; state.finish(); accusation = nil; visitPass.clear(); notice = "Session ended. Start again when you are ready."; save(); tick() }
    func startBreak(_ minutes: Int) {
        completedFocus = false
        showFocusCompletion = false
        state.startBreak(minutes: minutes)
        accusation = nil; visitPass.clear(); notice = ""; save(); tick()
    }
    func pauseBreak() { state.breakSession?.togglePause(); save(); tick() }
    func resetBreak() { state.breakSession?.reset(); save(); tick() }
    func endBreak() {
        state.cancelBreak(); save(); tick()
    }
    func returnToFocus() {
        completedFocus = false
        showFocusCompletion = false
        state.cancelBreak()
        if paused { state.resume() }
        save(); tick()
    }
    func dismissBreakReminder() { state.breakReminder = false; save() }
    func dismissFocusCompletion() { showFocusCompletion = false }
    func showWindow() {
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.title == "Guilty" }) {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        }
    }
    func tick() {
        breakRemaining = state.breakSession?.displaySecondsLeft() ?? 0
        if state.completeBreakIfNeeded() {
            save(); NSSound(named: "Glass")?.play(); showWindow()
        }
        remaining = Int(ceil(state.timeLeft()))
        if state.deadline != nil && remaining == 0 {
            completedFocus = true
            showFocusCompletion = true
            state.finish(); accusation = nil; visitPass.clear(); save(); notice = "Case closed. Your focus time is complete."; NSSound(named: "Glass")?.play()
            showWindow()
        }
        visitPass.observe(processID: NSWorkspace.shared.frontmostApplication?.processIdentifier)
        guard let app = NSWorkspace.shared.frontmostApplication,
              let id = app.bundleIdentifier, id != Bundle.main.bundleIdentifier else { return }
        if active && state.apps.contains(where: { $0.id == id }) {
            if !visitPass.allows(processID: app.processIdentifier) {
                accuse(key: "app:" + id, name: app.localizedName ?? id, app: app)
            }
        } else if aiReminder.isDue && AIUseDetection.appIDs.contains(id) {
            aiReminder.show()
        } else if browsers.contains(id), !checking,
                  active || (aiReminder.isDue && Date() >= nextReminderBrowserCheck) {
            nextReminderBrowserCheck = Date().addingTimeInterval(2)
            checkBrowser(app, id: id)
        } else if active, !browsers.contains(id), id.lowercased().contains("browser") || id == "org.mozilla.firefox" {
            browserStatus = "This browser is not supported. Add it to blocked apps during focus time."
        }
    }
    func dismissAIUseReminder() { aiReminder.dismiss() }

    func accuse(key: String, name: String, app: NSRunningApplication, page: String? = nil) {
        guard active else { return }
        app.hide()
        accusation = Accusation(key: key, name: name, app: app, page: page)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.title == "Guilty" })?.makeKeyAndOrderFront(nil)
    }
    func bypass() {
        guard let item = accusation, active else { accusation = nil; return }
        visitPass.allow(processID: item.app.processIdentifier, page: item.page); accusation = nil
        item.app.unhide(); item.app.activate(options: [.activateIgnoringOtherApps])
    }
    func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]; panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier, id != Bundle.main.bundleIdentifier,
                  !state.apps.contains(where: { $0.id == id }) else { continue }
            state.apps.append(.init(id: id, name: url.deletingPathExtension().lastPathComponent))
        }
        save()
    }
    func discoverGames() {
        for root in ["/Applications", NSHomeDirectory() + "/Applications"] {
            guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: root), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier,
                      let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String,
                      category.contains("games"), !state.apps.contains(where: { $0.id == id }) else { continue }
                state.apps.append(.init(id: id, name: url.deletingPathExtension().lastPathComponent))
            }
        }
        save(); notice = "Added games that declare a game category. Use Add app for any others."
    }
    private func checkBrowser(_ app: NSRunningApplication, id: String) {
        checking = true
        let session = state.deadline
        let generation = activationGeneration
        let expression = id == "com.apple.Safari" ? "URL of current tab of front window" : "URL of active tab of front window"
        let tabIdentity = id == "com.apple.Safari" ? "index of current tab of front window" : "id of active tab of front window"
        let source = "with timeout of 3 seconds\n tell application id \"\(id)\"\n if (count of windows) is 0 then return \"\"\n return {\(expression), (id of front window) as text, (\(tabIdentity)) as text}\n end tell\nend timeout"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var error: NSDictionary?
            let descriptor = NSAppleScript(source: source)?.executeAndReturnError(&error)
            let result = descriptor?.atIndex(1)?.stringValue
            let identity = (descriptor?.atIndex(2)?.stringValue ?? "") + ":" + (descriptor?.atIndex(3)?.stringValue ?? "")
            let failed = error != nil
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.checking = false
                guard self.activationGeneration == generation,
                      NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier else { return }
                self.browserStatus = failed ? "Cannot read \(app.localizedName ?? "browser"). Allow Guilty in System Settings → Privacy & Security → Automation, then reopen the browser." : "Checking \(app.localizedName ?? "browser") · website checks are working."
                guard !failed, let result else {
                    self.nextReminderBrowserCheck = Date().addingTimeInterval(60)
                    if self.active && self.state.deadline == session { self.visitPass.clear() }
                    return
                }

                if self.active && self.state.deadline == session {
                    let page = identity + ":" + result
                    self.visitPass.observe(processID: app.processIdentifier, page: page, checkingPage: true)
                    if let domain = self.state.blockedKeyword(for: result),
                       !self.visitPass.allows(processID: app.processIdentifier, page: page) {
                        self.accuse(key: "site:" + domain, name: domain, app: app, page: page)
                        return
                    }
                }
                if AIUseDetection.matchesWebsite(result) { self.aiReminder.show() }
            }
        }
    }
}
