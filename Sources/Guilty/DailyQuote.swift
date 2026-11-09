import Foundation

struct MovieQuote: Identifiable {
    let id: String
    let text: String
    let movie: String
    let year: Int
    let source: String
}

enum DailyQuote {
    // A civil date, not elapsed seconds: daylight-saving days still get one quote.
    static func index(on date: Date, timeZone: TimeZone = .current, count: Int = MovieQuoteCatalog.all.count) -> Int {
        precondition(count > 0)
        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let civilDate = utc.date(from: local.dateComponents([.year, .month, .day], from: date))!
        let epoch = utc.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let days = utc.dateComponents([.day], from: epoch, to: civilDate).day!
        return ((days % count) + count) % count
    }
    static func quote(on date: Date, timeZone: TimeZone = .current) -> MovieQuote {
        MovieQuoteCatalog.all[index(on: date, timeZone: timeZone)]
    }
}
