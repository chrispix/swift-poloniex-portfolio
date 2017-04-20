
import Foundation

public struct Holding: CustomStringConvertible {
    public let ticker: String
    let bitcoinValue: Double
    let availableAmount: Double
    let onOrders: Double
    public var orders = [Order]()
    var bitcoinMarketKey: String {
        return "BTC_\(ticker)"
    }
    public var isBitcoin: Bool {
        return ticker == "BTC"
    }
    var amount: Double {
        return availableAmount + onOrders
    }
    public var description: String {
        let o = orders.map({$0.summary(for: self)}).joined(separator: ", ")
        return "\(ticker): \(bitcoinValue.summary) BTC \(o)"
    }
    var bitcoinPrice: Double {
        return bitcoinValue / amount
    }

    static func ticker(fromBitcoinMarketKey key: String) -> String? {
        guard key.hasPrefix("BTC_") else { return nil }
        return key.replacingOccurrences(of: "BTC_", with: "")
    }

    init(ticker: String, bitcoinValue: Double, availableAmount: Double, onOrders: Double) {
        self.ticker = ticker
        self.bitcoinValue = bitcoinValue
        self.availableAmount = availableAmount
        self.onOrders = onOrders
    }

    mutating func addOrder(_ order: Order) {
        orders.append(order)
    }

    func dollarValue(btcPrice: Double) -> String {
        return (bitcoinValue * btcPrice).dollars
    }
}

enum BuySell: String {
    case buy
    case sell
}

public struct Order: CustomStringConvertible {
    let price: Double
    let amount: Double
    let type: BuySell
    var proceeds: Double {
        return price * amount
    }

    public var description: String {
        return "\(type) \(amount.rounded) at \(price.threeSignificant) for \(proceeds.summary) BTC"
    }

    func summary(for holding: Holding) -> String {
        let ratio = amount / holding.amount
        return "\(type) \(ratio.roundedPercent) for \(proceeds.summary) BTC"
    }
}

public struct Portfolio: CustomStringConvertible {
    let holdings: [Holding]
    let btcPrice: Double?
    private func total() -> Double {
        return holdings.reduce(0, { sum, holding in
            return sum + holding.bitcoinValue
        })
    }

    public init(holdings: [Holding], btcPrice: Double?) {
        self.holdings = holdings
        self.btcPrice = btcPrice
    }

    public var summary: String {
        let 💰 = btcPrice != nil ? (btcPrice! * total()).dollars : ""
        return "Total: \(total().summary) BTC \(💰)"
    }

    public var description: String {
        let sorted = holdings.sorted(by: { $0.ticker < $1.ticker })
        let all: [String] = sorted.map({$0.description})
        let price = btcPrice != nil ? "BTC price: \(btcPrice!.dollars)\n" : ""
        return "\(price)\(all.joined(separator: "\n"))\n\(summary)"
    }
}
