import AppKit
import SwiftUI

enum AIUseDetection {
    static let appIDs: Set<String> = [
        "com.openai.chat", "com.openai.codex", "com.anthropic.claudefordesktop",
        "com.todesktop.230313mzl4w4u92", "com.exafunction.windsurf"
    ]

    static let domains = [
        "chatgpt.com", "chat.openai.com", "claude.ai", "gemini.google.com",
        "aistudio.google.com", "notebooklm.google.com", "copilot.microsoft.com",
        "perplexity.ai", "grok.com", "meta.ai", "chat.deepseek.com",
        "chat.mistral.ai", "poe.com", "character.ai", "you.com", "chat.qwen.ai",
        "lovable.dev", "bolt.new", "v0.dev"
    ]

    static func matchesWebsite(_ address: String) -> Bool {
        guard let url = URLComponents(string: address),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return false }
        if host == "github.com" {
            return url.path == "/copilot" || url.path.hasPrefix("/copilot/")
        }
        if host == "huggingface.co" {
            return url.path == "/chat" || url.path.hasPrefix("/chat/")
        }
        return domains.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}

@MainActor
final class AIUseReminder {
    static let enabledKey = "aiUseReminderEnabled"
    private let lastShownKey = "aiUseReminderLastShown"
    private let cooldown: TimeInterval = 10 * 60
    private let defaults = UserDefaults.standard
    private var panel: NSPanel?
    private var dismissal: Task<Void, Never>?

    var isDue: Bool {
        guard defaults.object(forKey: Self.enabledKey) as? Bool ?? true else { return false }
        guard let lastShown = defaults.object(forKey: lastShownKey) as? Date else { return true }
        let elapsed = Date().timeIntervalSince(lastShown)
        return elapsed >= cooldown || elapsed < 0
    }

    func show() {
        guard isDue, let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main else { return }

        let content = NSHostingView(rootView: AIUseReminderCard { [weak self] in self?.dismiss() })
        let size = content.fittingSize
        let visible = screen.visibleFrame
        let frame = NSRect(x: visible.maxX - size.width - 18, y: visible.maxY - size.height - 16,
                           width: size.width, height: size.height)
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.contentView = content
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        self.panel = panel
        panel.orderFrontRegardless()
        defaults.set(Date(), forKey: lastShownKey)
        dismissal = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            if !Task.isCancelled { self?.dismiss() }
        }
    }

    func dismiss() {
        dismissal?.cancel()
        dismissal = nil
        panel?.orderOut(nil)
        panel = nil
    }
}

private struct AIUseReminderCard: View {
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Keep it yours", systemImage: "sparkles")
                .font(.headline)
            Text("Use AI for ideas or feedback. Think it through and put the answer in your own words.")
                .fixedSize(horizontal: false, vertical: true)
            Button("Got it", action: dismiss)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(width: 330)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
