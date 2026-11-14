import XCTest
@testable import Guilty

final class DailyQuoteTests: XCTestCase {
    private let singapore = TimeZone(identifier: "Asia/Singapore")!
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    func testCatalogHasAFullLeapYearOfUniqueQuotes() {
        let quotes = MovieQuoteCatalog.all
        XCTAssertEqual(quotes.count, 366)
        XCTAssertEqual(Set(quotes.map(\.id)).count, quotes.count)
        XCTAssertEqual(Set(quotes.map { $0.text.lowercased() }).count, quotes.count)
        let normalized = quotes.map { quote in
            quote.text.lowercased().filter { $0.isLetter || $0.isNumber }
        }
        XCTAssertEqual(Set(normalized).count, quotes.count)
        for quote in quotes {
            XCTAssertFalse(quote.movie.isEmpty)
            XCTAssertFalse(quote.text.isEmpty)
            XCTAssertEqual(URL(string: quote.source)?.scheme, "https")
        }
    }
    func testRequestedNolanFilmsAreIncluded() {
        let films = Set(MovieQuoteCatalog.all.map(\.movie))
        XCTAssertTrue(films.contains("Interstellar"))
        XCTAssertTrue(films.contains("Inception"))
    }
    func testSameLocalDayKeepsSameQuoteAcrossReopens() {
        let morning = date("2026-11-09T00:00:00Z")
        let night = date("2026-11-09T15:59:59Z")
        XCTAssertEqual(DailyQuote.quote(on: morning, timeZone: singapore).id, DailyQuote.quote(on: night, timeZone: singapore).id)
        XCTAssertNotEqual(DailyQuote.quote(on: night, timeZone: singapore).id,
                          DailyQuote.quote(on: date("2026-11-09T16:00:00Z"), timeZone: singapore).id)
    }
    func testNoRepeatsAcrossFullCycleIncludingLeapDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = singapore
        let start = date("2028-02-01T04:00:00Z")
        let ids = (0..<MovieQuoteCatalog.all.count).map {
            DailyQuote.quote(on: calendar.date(byAdding: .day, value: $0, to: start)!, timeZone: singapore).id
        }
        XCTAssertEqual(Set(ids).count, MovieQuoteCatalog.all.count)
        let nextCycle = calendar.date(byAdding: .day, value: MovieQuoteCatalog.all.count, to: start)!
        XCTAssertEqual(DailyQuote.quote(on: start, timeZone: singapore).id, DailyQuote.quote(on: nextCycle, timeZone: singapore).id)
    }
    func testDaylightSavingAndDatesBeforeEpoch() {
        let zone = TimeZone(identifier: "America/New_York")!
        let count = MovieQuoteCatalog.all.count
        let before = DailyQuote.index(on: date("2026-03-08T05:00:00Z"), timeZone: zone)
        let after = DailyQuote.index(on: date("2026-03-09T04:00:00Z"), timeZone: zone)
        XCTAssertEqual(after, (before + 1) % count)
        let fallBefore = DailyQuote.index(on: date("2026-11-01T04:00:00Z"), timeZone: zone)
        let fallAfter = DailyQuote.index(on: date("2026-11-02T05:00:00Z"), timeZone: zone)
        XCTAssertEqual(fallAfter, (fallBefore + 1) % count)
        XCTAssertGreaterThanOrEqual(DailyQuote.index(on: date("2020-01-01T00:00:00Z"), timeZone: zone), 0)
    }
}
