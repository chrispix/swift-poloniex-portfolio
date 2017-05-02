
import XCTest
@testable import poloniex

class HoldingTests: XCTestCase {
	private let dateParser: DateFormatter = {
		let parser = DateFormatter()
		parser.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
		return parser
	}()

	func testMarketKey() {
		let holding = Holding(ticker: "FOO", bitcoinValue: 0, availableAmount: 0, onOrders: 0)

        XCTAssertEqual(holding.bitcoinMarketKey, "BTC_FOO", "Incorrect market key")
	}

	func testExecutedOrders() {
		let p1 = ExecutedOrder(price: 0.3, amount: 1, type: .buy, fee: 0, total: 0.3, date: dateParser.date(from: "2016-04-01 08:08:40")!)
		let p2 = ExecutedOrder(price: 1, amount: 1, type: .buy, fee: 0, total: 1, date: dateParser.date(from: "2016-04-02 08:08:40")!)
		let p3 = ExecutedOrder(price: 0.2, amount: 1, type: .buy, fee: 0, total: 0.2, date: dateParser.date(from: "2016-04-03 08:08:40")!)
		let s1 = ExecutedOrder(price: 1, amount: 0.5, type: .sell, fee: 0, total: 0.5, date: dateParser.date(from: "2016-04-04 08:08:40")!)
		let s2 = ExecutedOrder(price: 2, amount: 1, type: .sell, fee: 0, total: 2, date: dateParser.date(from: "2016-04-05 08:08:40")!)

		let orders = [p1, p2, p3, s1, s2].mostRecentFirst

		XCTAssertEqual(orders, [s2, s1, p3, p2, p1], "Sorted incorrectly")

		XCTAssertEqual(orders.purchases, [p3, p2, p1], "Incorrect purchases")
		XCTAssertEqual(orders.sales, [s2, s1], "Incorrect sales")
		XCTAssertEqual(orders.sold, 1.5, "Incorrect amount sold")
		XCTAssertEqual(orders.salesProceeds, 2.5, "Incorrect sales proceeds")
		XCTAssertEqual(orders.realizedGains, 1.7, "Incorrect realized gains--cost 0.3 + 0.5, sold for 2.5")

		let holding = Holding(ticker: "FOO", bitcoinValue: 20, availableAmount: 1, onOrders: 0.5)

		XCTAssertEqual(orders.costBasis(for: holding), 0.7, "Incorrect cost basis--cost 0.5 + 0.2")
	}
}
