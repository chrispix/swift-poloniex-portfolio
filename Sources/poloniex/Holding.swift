
import Foundation
import UIKit

struct PriceRange {
    let low: Double
    let high: Double
    let average: Double

    init(prices: [Double]) {
        low = prices.min()!
        high = prices.max()!
        let total = prices.reduce(0, +)
        average = total/Double(prices.count)
    }
}

public struct Holding: CustomStringConvertible {
    public let ticker: String
    let availableAmount: Double
    let onOrders: Double
    let bitcoinPrice: Double
    public var orders = [Order]()
    var priceRange: PriceRange?

    var bitcoinMarketKey: String {
        return "BTC-\(ticker)"
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

    // greenest if 50% below average price
    // reddest if 50% above average price
    var backgroundColor: UIColor {
        guard let priceRange = priceRange else { return .clear }
        var deviationFromAverage = (bitcoinPrice - priceRange.average) / priceRange.average
        deviationFromAverage = min(deviationFromAverage, 0.5)
        deviationFromAverage = max(deviationFromAverage, -0.5)
        deviationFromAverage = deviationFromAverage + 0.5
        // convert 0-1 to .33 - 0
        let hue = CGFloat((1.0 - deviationFromAverage) * 0.33)
        return UIColor(hue: hue, saturation: 0.15, brightness: 1.0, alpha: 1.0)
    }

    var bitcoinValue: Double { return amount * bitcoinPrice }

    var likeliestOrderToFill: Order? {
        guard let first = orders.first else { return nil }

        return orders.reduce(first, { (previous, order) -> Order in
            let difference = order.likelihoodToFill(currentPrice: bitcoinPrice)
            let previousDifference = previous.likelihoodToFill(currentPrice: bitcoinPrice)
            return difference < previousDifference ? order : previous
        })
    }

    static func ticker(fromBitcoinMarketKey key: String) -> String? {
        guard key.hasPrefix("BTC-") else { return nil }
        return key.replacingOccurrences(of: "BTC-", with: "")
    }

    init(ticker: String, bitcoinPrice: Double, availableAmount: Double, onOrders: Double) {
        self.ticker = ticker
        self.availableAmount = availableAmount
        self.onOrders = onOrders
        self.bitcoinPrice = bitcoinPrice
    }

    mutating func addOrder(_ order: Order) {
        orders.append(order)
    }

    func dollarValue(btcPrice: Double) -> String {
        return (bitcoinValue * btcPrice).dollars
    }
}

enum BuySell: String {
    case buy = "LIMIT_BUY"
    case sell = "LIMIT_SELL"
}

public struct Order: CustomStringConvertible {
    let price: Double
    let amount: Double
    let type: BuySell
    var proceeds: Double {
        return price * amount
    }
    public var description: String {
        return "\(type) \(amount.summary) for \(proceeds.summary) BTC"
    }

    func summary(for holding: Holding) -> String {
        let ratio = amount / holding.amount
        return "\(type) \(ratio.roundedPercent) for \(proceeds.summary) BTC"
    }

    /* percentage difference between order price and current price */
    func likelihoodToFill(currentPrice: Double) -> Double {
        return Swift.abs((price - currentPrice) / currentPrice)
    }
}

public struct Proceeds {
    let btc: Double
    let altcoin: Double
}

public struct ExecutedOrder: CustomStringConvertible, Equatable {
    let price: Double
    let amount: Double
    let type: BuySell
    let fee: Double // percentage
    let total: Double
    let date: Date
    var proceeds: Proceeds {
        switch type {
        case .buy:
            return Proceeds(btc: -total, altcoin: amount * (1.0 - fee))
        case .sell:
            // fee is already taken out of total on sales
            return Proceeds(btc: total, altcoin: -amount)
        }
    }

    public var description: String {
        return "\(type) \(amount) on \(date)"
    }
}

public func ==(lhs: ExecutedOrder, rhs: ExecutedOrder) -> Bool {
    return lhs.price == rhs.price &&
        lhs.amount == rhs.amount &&
        lhs.type == rhs.type &&
        lhs.fee == rhs.fee &&
        lhs.date == rhs.date &&
        lhs.total == rhs.total
}

/* TODO: Assumes orders are newest to oldest. Sort by date to be sure. */
public extension Array where Element == ExecutedOrder {
    var mostRecentFirst: [ExecutedOrder] {
        return sorted(by: {
            return $0.date > $1.date
        })
    }

    var oldestFirst: [ExecutedOrder] {
        return sorted(by: {
            return $0.date < $1.date
        })
    }

    var purchases: [ExecutedOrder] {
        return filter({ order in
            order.type == .buy
        })
    }

    var sales: [ExecutedOrder] {
        return filter({ order in
            order.type == .sell
        })
    }

    var sold: Double {
        return sales.reduce(0.0) { (previous, order) -> Double in
            return previous + order.amount
        }
    }

    var salesProceeds: Double {
        return sales.reduce(0.0) { (previous, order) -> Double in
            return previous + order.proceeds.btc
        }
    }

    func costBasis(for holding: Holding) -> Double {
        var unaccountedShares = holding.amount
        var cost: Double = 0
        // fifo
        for purchase in purchases where unaccountedShares > 0 {
            let shares = Swift.min(unaccountedShares, purchase.proceeds.altcoin)
            let adjustedSharePrice = Swift.abs(purchase.proceeds.btc / purchase.amount)
            cost += (shares * adjustedSharePrice)
            unaccountedShares -= shares
        }
        return cost
    }

    struct RealizedGains {
        let cost: Double
        let proceeds: Double
        var gain: Double {
            return proceeds - cost
        }
        var percentGain: Double {
            return gain / cost
        }
    }

    var realizedGains: RealizedGains {
        let realized: RealizedGains = {
            var unaccountedShares = sold
            var cost: Double = 0
            // fifo
            for purchase in purchases.oldestFirst where unaccountedShares > 0 {
                let shares = Swift.min(unaccountedShares, purchase.proceeds.altcoin)
                let adjustedSharePrice = Swift.abs(purchase.proceeds.btc / purchase.proceeds.altcoin)
                cost += (shares * adjustedSharePrice)
                unaccountedShares -= shares
            }
            return RealizedGains(cost: cost, proceeds: salesProceeds)
        }()

        return realized
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
