import SwiftUI
import AppKit

@main
struct GuiltyApp: App {
    @StateObject private var model = FocusModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        Window("Guilty", id: "main") {
            ContentView(model: model)
                .onAppear { delegate.model = model; NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true) }
        }
        .defaultSize(width: 1000, height: 780)
        .windowResizability(.contentMinSize)
        MenuBarExtra {
            Text(model.hasSession ? "Focus time: \(model.clock)" : "Ready for your next session")
            Button("Open Guilty") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first(where: { $0.title == "Guilty" })?.makeKeyAndOrderFront(nil)
            }
            if model.hasSession {
                Button(model.paused ? "Resume timer" : "Pause timer") { model.pauseOrResume() }
                Button("Reset timer") { model.reset() }
                Button("End timer") { model.end() }
            }
            Divider()
            Button("Quit Guilty") { NSApp.terminate(nil) }
        } label: {
            Label(model.hasSession ? model.clock : "Guilty", systemImage: "timer")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: FocusModel?
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model?.hasSession == true else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Your focus timer is still running"
        alert.informativeText = "Quitting stops protection. The timer will resume if you reopen Guilty before it ends."
        alert.addButton(withTitle: "Keep focusing")
        alert.addButton(withTitle: "Quit anyway")
        return alert.runModal() == .alertFirstButtonReturn ? .terminateCancel : .terminateNow
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        sender.windows.first(where: { $0.title == "Guilty" })?.makeKeyAndOrderFront(nil)
        return true
    }
}

private let ink = Color(red: 0.10, green: 0.14, blue: 0.13)
private let paper = Color(red: 0.96, green: 0.95, blue: 0.91)
private let accent = Color(red: 0.77, green: 0.95, blue: 0.39)

struct ContentView: View {
    @ObservedObject var model: FocusModel
    @State private var minutes = 25
    @State private var domain = ""
    @State private var inputError = ""
    var body: some View {
        ZStack {
            paper.ignoresSafeArea()
            HStack(spacing: 0) {
                sidebar
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        HStack {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("LESS SCROLLING. MORE DOING.").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
                                Text(model.paused ? "Take a breath." : model.hasSession ? "Your time. Protected." : "Make time for what matters.")
                                    .font(.system(size: 30, weight: .semibold, design: .serif))
                            }
                            Spacer()
                            Image(systemName: "sparkle").font(.title).foregroundStyle(ink.opacity(0.4))
                        }
                        timerCard
                        HStack(alignment: .top, spacing: 16) {
                            appList.frame(maxWidth: .infinity)
                            siteList.frame(maxWidth: .infinity)
                        }
                        if !model.notice.isEmpty { Text(model.notice).font(.callout).foregroundStyle(ink.opacity(0.7)) }
                        Label(model.browserStatus, systemImage: "info.circle")
                            .font(.system(size: 11)).foregroundStyle(ink.opacity(0.6))
                        Text("Keep Guilty open for protection. Supported browsers: Safari, Chrome, Edge, Brave, Vivaldi and Opera. Other browsers can be added to blocked apps.")
                            .font(.system(size: 11)).foregroundStyle(ink.opacity(0.6))
                    }.padding(32)
                }
            }
            if let accusation = model.accusation {
                ink.opacity(0.78).ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.shield.fill").font(.system(size: 48)).foregroundStyle(ink)
                    Text("CAUGHT IN THE ACT").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(3)
                    Text("You R Found Guilty").font(.system(size: 38, weight: .bold, design: .serif))
                    Text("\(accusation.name) can wait.\nYou have \(model.clock) left to focus.")
                        .multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.7))
                    Button { model.accusation = nil } label: {
                        Text("Back to focus  ↗").fontWeight(.semibold).frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.plain).background(ink).foregroundStyle(paper).clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Wrongly Accused") { model.bypass() }.buttonStyle(.plain).font(.system(size: 12)).underline()
                    Text("Allow this visit only. Leaving and returning triggers a new warning.")
                        .font(.system(size: 10)).foregroundStyle(ink.opacity(0.55))
                }
                .padding(40).frame(width: 440).background(paper).clipShape(RoundedRectangle(cornerRadius: 24)).shadow(radius: 30)
            }
        }
        .foregroundStyle(ink).frame(minWidth: 880, minHeight: 660)
        .preferredColorScheme(.light)
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack(spacing: 8) {
                Image(systemName: "checkerboard.shield").font(.title2)
                Text("guilty.").font(.system(size: 31, weight: .bold, design: .serif))
            }
            Text("A LITTLE DISCIPLINE.\nA LOT OF POSSIBILITY.")
                .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1).lineSpacing(5).fixedSize(horizontal: false, vertical: true).opacity(0.5)
            Label("Focus chamber", systemImage: "timer").font(.system(size: 12, weight: .semibold))
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(accent.opacity(0.13)).clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
            Image(systemName: "hourglass").font(.system(size: 42, weight: .ultraLight)).foregroundStyle(accent)
            Text("Your distractions\ncan take a number.")
                .font(.system(size: 19, design: .serif)).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
            Text("Set a timer. Stay with it.\nWe’ll handle the objections.").font(.system(size: 11)).lineSpacing(4).opacity(0.55)
            Divider().overlay(paper.opacity(0.2))
            Label(model.hasSession ? "COURT IN SESSION" : "READY WHEN YOU ARE", systemImage: "circle.fill")
                .font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(accent)
        }.padding(24).frame(width: 210).frame(maxHeight: .infinity).background(ink).foregroundStyle(paper)
    }
    private var timerCard: some View {
        VStack(spacing: 18) {
            HStack {
                Label(model.paused ? "SESSION PAUSED" : model.hasSession ? "FOCUS IN PROGRESS" : "YOUR NEXT FOCUS SESSION", systemImage: "circle.dotted")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1)
                Spacer()
                Text(model.hasSession ? "STAY WITH IT" : "NO DISTRACTIONS")
                    .font(.system(size: 9, design: .monospaced)).opacity(0.5)
            }
            Text(model.hasSession ? model.clock : String(format: "%02d:00", minutes))
                .font(.system(size: 80, weight: .light, design: .monospaced)).monospacedDigit()
                .accessibilityLabel("Time remaining").accessibilityValue(model.hasSession ? model.clock : "\(minutes) minutes")
            if model.hasSession {
                ProgressView(value: max(0, min(1, 1 - Double(model.remaining) / model.state.duration))).tint(ink)
                Text(model.paused ? "Timer and blocking are paused." : "You made a promise to yourself. Keep going.").font(.system(size: 12)).opacity(0.65)
                HStack(spacing: 16) {
                    Button(model.paused ? "Resume" : "Pause") { model.pauseOrResume() }
                    Button("Reset") { model.reset() }
                    Button("End timer") { model.end() }
                }.buttonStyle(.bordered).controlSize(.large)
            } else {
                HStack(spacing: 10) {
                    ForEach([15, 25, 45, 60], id: \.self) { value in
                        Button("\(value)m") { minutes = value }.buttonStyle(.plain)
                            .padding(.horizontal, 13).padding(.vertical, 7)
                            .background(minutes == value ? ink : ink.opacity(0.07))
                            .foregroundStyle(minutes == value ? paper : ink).clipShape(Capsule())
                    }
                    Stepper(value: $minutes, in: 1...480) {
                        TextField("Minutes", value: $minutes, format: .number).frame(width: 40)
                    }.fixedSize().help("Custom time: 1–480 minutes")
                }
                Button { minutes = min(480, max(1, minutes)); model.start(minutes) } label: {
                    HStack { Spacer(); Text("Start focus session"); Spacer(); Image(systemName: "arrow.up.right") }
                        .font(.system(size: 14, weight: .semibold)).padding(15)
                }.buttonStyle(.plain).background(ink).foregroundStyle(paper).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }.padding(24).background(accent).clipShape(RoundedRectangle(cornerRadius: 18))
    }
    private var appList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Apps on trial", systemImage: "square.stack.3d.up").font(.system(size: 16, weight: .semibold, design: .serif))
            Text("Games and other distractions").font(.system(size: 11)).opacity(0.55)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(model.state.apps) { app in
                        HStack {
                            Text(app.name).lineLimit(1)
                            Spacer()
                            if !model.hasSession {
                                Button { model.state.apps.removeAll { $0.id == app.id }; model.save() } label: { Image(systemName: "minus.circle") }
                                    .buttonStyle(.plain).accessibilityLabel("Remove \(app.name)")
                            }
                        }.font(.system(size: 12))
                    }
                }
            }.frame(height: 133)
            HStack {
                Button("+ Add app") { model.addApp() }
                Button("Find games") { model.discoverGames() }
            }.font(.system(size: 11)).disabled(model.hasSession)
        }.padding(18).background(.white.opacity(0.75)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private var siteList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Words on trial", systemImage: "globe").font(.system(size: 16, weight: .semibold, design: .serif))
            Text("Matches anywhere in a URL").font(.system(size: 11)).opacity(0.55)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(model.state.domains, id: \.self) { site in
                        HStack {
                            Text(site).lineLimit(1); Spacer()
                            if !model.hasSession {
                                Button { model.state.domains.removeAll { $0 == site }; model.save() } label: { Image(systemName: "minus.circle") }
                                    .buttonStyle(.plain).accessibilityLabel("Remove \(site)")
                            }
                        }.font(.system(size: 12))
                    }
                }
            }.frame(height: 133)
            HStack {
                TextField("e.g. fandom", text: $domain).onSubmit(addDomain)
                Button("Add", action: addDomain)
            }.disabled(model.hasSession)
            if !inputError.isEmpty { Text(inputError).font(.caption).foregroundStyle(.red) }
        }.padding(18).background(.white.opacity(0.75)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private func addDomain() {
        guard !model.hasSession else { return }
        guard let normalized = FocusState.normalizeKeyword(domain) else { inputError = "Enter a keyword, such as fandom or youtube."; return }
        if !model.state.domains.contains(normalized) { model.state.domains.append(normalized); model.save() }
        domain = ""; inputError = ""
    }
}
