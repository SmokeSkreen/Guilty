import SwiftUI

struct DailyQuoteView: View {
    let onFocus: () -> Void
    private let ink = Color(red: 0.10, green: 0.14, blue: 0.13)
    private let lime = Color(red: 0.77, green: 0.95, blue: 0.39)

    var body: some View {
        // Refresh after midnight even when this page stays open overnight.
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let quote = DailyQuote.quote(on: context.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("A LITTLE MOVIE MAGIC").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
                            Text("Quote of the Day").font(.system(size: 34, weight: .semibold, design: .serif))
                        }
                        Spacer()
                        Image(systemName: "film").font(.system(size: 28, weight: .light))
                    }
                    VStack(alignment: .leading, spacing: 28) {
                        HStack {
                            Label("TODAY’S PICK", systemImage: "sparkle")
                            Spacer()
                            Text(context.date, format: .dateTime.day().month(.abbreviated).year())
                        }.font(.system(size: 11, weight: .medium, design: .monospaced))
                        Image(systemName: "quote.opening").font(.system(size: 44, weight: .black)).opacity(0.25)
                        Text(quote.text)
                            .font(.system(size: 36, weight: .medium, design: .serif))
                            .lineSpacing(8).fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .accessibilityLabel("Today’s movie quote: \(quote.text)")
                        Divider().overlay(ink.opacity(0.2))
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(quote.movie).font(.system(size: 17, weight: .semibold))
                                Text(String(quote.year)).font(.system(size: 12, design: .monospaced)).opacity(0.6)
                            }
                            Spacer()
                            Image(systemName: "ticket").font(.title2)
                        }
                    }.padding(32).frame(maxWidth: .infinity, alignment: .leading)
                        .background(lime).clipShape(RoundedRectangle(cornerRadius: 22))
                    HStack {
                        Label("A new quote each day. A fresh reason to begin.", systemImage: "sunrise")
                            .font(.system(size: 12)).foregroundStyle(ink.opacity(0.65))
                        Spacer()
                    }
                    HStack(spacing: 20) {
                        Button(action: onFocus) {
                            Label("Put it into practice", systemImage: "arrow.right")
                                .font(.system(size: 13, weight: .semibold)).padding(14)
                        }.buttonStyle(.plain).background(ink).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        if let url = URL(string: quote.source) {
                            Link("Quote source ↗", destination: url).font(.system(size: 12)).tint(ink)
                        }
                    }
                    Text("Changes at midnight in your Mac’s time zone. Works offline, with no repeats for \(MovieQuoteCatalog.all.count) days.")
                        .font(.system(size: 11)).foregroundStyle(ink.opacity(0.55))
                }.padding(32)
            }
        }.foregroundStyle(ink)
    }
}
