
import XCTest
@testable import poloniex

class HoldingTests: XCTestCase {
	func testMarketKey() {
		let holding = Holding(ticker: "FOO", bitcoinValue: 0, availableAmount: 0, onOrders: 0)

        XCTAssertEqual(holding.bitcoinMarketKey, "BTC_FOO", "Incorrect market key")
	}
}
