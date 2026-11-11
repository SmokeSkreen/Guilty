import SwiftUI

struct RelaxationView: View {
    @ObservedObject var model: FocusModel
    let onFocus: () -> Void
    @State private var minutes = 10
    private let ink = Color(red: 0.10, green: 0.14, blue: 0.13)
    private let lavender = Color(red: 0.84, green: 0.82, blue: 0.97)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EVEN THE COURT TAKES A BREAK.")
                            .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5)
                        Text("Relaxation Chamber").font(.system(size: 32, weight: .semibold, design: .serif))
                    }
                    Spacer()
                    Image(systemName: "cup.and.saucer").font(.system(size: 30, weight: .light))
                }
                VStack(spacing: 24) {
                    HStack {
                        Label(model.hasBreak ? (model.state.breakSession?.paused == true ? "BREAK PAUSED" : "COURT IN RECESS") : "YOUR NEXT BREATHER", systemImage: "leaf")
                        Spacer()
                        Text("ALL APPS ALLOWED")
                    }.font(.system(size: 10, weight: .semibold, design: .monospaced))
                    Text(model.hasBreak ? model.breakClock : String(format: "%02d:00", minutes))
                        .font(.system(size: 80, weight: .light, design: .monospaced)).monospacedDigit()
                        .accessibilityLabel("Relaxation time").accessibilityValue(model.hasBreak ? model.breakClock : "\(minutes) minutes")
                    if let session = model.state.breakSession {
                        ProgressView(value: max(0, min(1, 1 - Double(model.breakRemaining) / session.displayDuration))).tint(ink)
                        Text("No guilty verdicts here. Enjoy your break.").font(.system(size: 14))
                        HStack(spacing: 16) {
                            Button(session.paused ? "Resume break" : "Pause break") { model.pauseBreak() }
                            Button("Reset break") { model.resetBreak() }
                            Button("End break") { model.endBreak() }
                        }.buttonStyle(.bordered).controlSize(.large)
                    } else {
                        HStack(spacing: 12) {
                            ForEach([5, 10, 15, 30], id: \.self) { value in
                                Button("\(value)m") { minutes = value }
                                    .buttonStyle(.plain).padding(.horizontal, 13).padding(.vertical, 8)
                                    .background(minutes == value ? ink : ink.opacity(0.07))
                                    .foregroundStyle(minutes == value ? .white : ink).clipShape(Capsule())
                            }
                            TextField("Minutes", value: $minutes, format: .number)
                                .frame(width: 44).accessibilityLabel("Custom break minutes")
                            Stepper("", value: $minutes, in: 1...480).labelsHidden()
                        }
                        Button {
                            minutes = min(480, max(1, minutes)); model.startBreak(minutes)
                        } label: {
                            HStack { Spacer(); Text("Start relaxation"); Spacer(); Image(systemName: "arrow.up.right") }
                                .font(.system(size: 14, weight: .semibold)).padding(15)
                        }.buttonStyle(.plain).background(ink).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }.padding(26).background(lavender).clipShape(RoundedRectangle(cornerRadius: 20))
                VStack(alignment: .leading, spacing: 16) {
                    Label("A proper break. Without the guilt.", systemImage: "sparkles")
                        .font(.system(size: 20, weight: .medium, design: .serif))
                    Text("Games, videos, and every other app are allowed during your break. When time is up, Guilty plays a sound and brings up a reminder to come back.")
                        .font(.system(size: 14)).lineSpacing(5)
                    Text(model.paused ? "Your focus timer is paused. Resume it whenever you are ready." : "Starting a break pauses any running focus timer. It resumes only when you choose to return.")
                        .font(.system(size: 12)).foregroundStyle(ink.opacity(0.65))
                    if model.paused {
                        Button("Return to focus", action: onFocus).buttonStyle(.bordered).controlSize(.large)
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 16))
                Label("Keep Guilty running for the reminder. If your Mac is asleep, it will remind you when it wakes.", systemImage: "info.circle")
                    .font(.system(size: 11)).foregroundStyle(ink.opacity(0.6))
            }.padding(32)
        }.foregroundStyle(ink)
    }
}
