
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
		XCTAssertEqual(orders.realizedGains.gain, 1.7, "Incorrect realized gains--cost 0.3 + 0.5, sold for 2.5")

		let holding = Holding(ticker: "FOO", bitcoinValue: 20, availableAmount: 1, onOrders: 0.5)

		XCTAssertEqual(orders.costBasis(for: holding), 0.7, "Incorrect cost basis--cost 0.5 + 0.2")
	}

	func testFee() {
		let p1 = ExecutedOrder(price: 0.000541, amount: 50, type: .buy, fee: 0.0015, total: 0.02705, date: dateParser.date(from: "2016-04-01 08:08:40")!)
		let s1 = ExecutedOrder(price: 0.000275, amount: 100, type: .sell, fee: 0.0015, total: 0.02745875, date: dateParser.date(from: "2016-04-04 08:08:40")!)

		XCTAssertEqualWithAccuracy(p1.proceeds.btc, -0.02705, accuracy: 0.00001, "Incorrect proceeds on purchase")
		XCTAssertEqualWithAccuracy(p1.proceeds.altcoin, 49.925, accuracy: 0.001, "Incorrect proceeds on purchase")
		XCTAssertEqualWithAccuracy(s1.proceeds.btc, 0.02745875, accuracy: 0.00000001, "Incorrect proceeds on sale")
		XCTAssertEqual(s1.proceeds.altcoin, -100, "Incorrect proceeds on sale")
	}

    /*
	first purchase yields 49.925 for 0.02705 BTC
	second share price is 0.0002210225 (0.02314330 / (104.97259704 * (1 - .0025)))
	second purchase yields 50.075 for 0.0110677005 BTC
	Total cost: 0.0381177005 BTC
	*/
	func testRealizedGains() {
		let p1 = ExecutedOrder(price: 0.000541, amount: 50, type: .buy, fee: 0.0015, total: 0.02705, date: dateParser.date(from: "2016-04-01 08:08:40")!)
		let p2 = ExecutedOrder(price: 0.00022047, amount: 104.97259704, type: .buy, fee: 0.0025, total: 0.02314330, date: dateParser.date(from: "2016-04-02 08:08:40")!)
		let s1 = ExecutedOrder(price: 0.000275, amount: 100, type: .sell, fee: 0.0015, total: 0.02745875, date: dateParser.date(from: "2016-04-04 08:08:40")!)

		let orders = [p1, p2, s1].mostRecentFirst

		XCTAssertEqualWithAccuracy(orders.realizedGains.cost, 0.0381177005, accuracy: 0.0000000001, "Incorrect cost")
		XCTAssertEqualWithAccuracy(orders.realizedGains.proceeds, 0.02745875, accuracy: 0.00000001, "Incorrect proceeds")
		XCTAssertEqualWithAccuracy(orders.realizedGains.gain, -0.0106589505, accuracy: 0.0000000001, "Incorrect realized gains -- cost 0.0381177005, sold for 0.02745875")
		XCTAssertEqualWithAccuracy(orders.realizedGains.percentGain, -0.2796, accuracy: 0.0001, "Incorrect realized gain percent")
	}

}
