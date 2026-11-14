import XCTest
@testable import Guilty

final class AIUseDetectionTests: XCTestCase {
    func testMatchesAIHostsAndSpecificSections() {
        XCTAssertTrue(AIUseDetection.matchesWebsite("https://chatgpt.com/c/example"))
        XCTAssertTrue(AIUseDetection.matchesWebsite("https://www.perplexity.ai/"))
        XCTAssertTrue(AIUseDetection.matchesWebsite("https://github.com/copilot/example"))
        XCTAssertTrue(AIUseDetection.matchesWebsite("https://huggingface.co/chat/"))
    }

    func testIgnoresAIWordsOnUnrelatedPages() {
        XCTAssertFalse(AIUseDetection.matchesWebsite("https://example.com/?next=chatgpt.com"))
        XCTAssertFalse(AIUseDetection.matchesWebsite("https://chatgpt.com.example.org/"))
        XCTAssertFalse(AIUseDetection.matchesWebsite("https://github.com/example/copilot"))
        XCTAssertFalse(AIUseDetection.matchesWebsite("https://huggingface.co/models"))
    }
}
