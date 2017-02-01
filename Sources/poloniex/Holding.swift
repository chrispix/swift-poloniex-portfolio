
import Foundation

struct Holding: CustomStringConvertible {
  let ticker: String
  let bitcoinValue: Double
  let availableAmount: Double
  let onOrders: Double
  var orders = [Order]()
  var bitcoinMarketKey: String {
      return "BTC_\(ticker)"
  }
  var isBitcoin: Bool {
      return ticker == "BTC"
  }
  var amount: Double {
      return availableAmount + onOrders
  }
  var description: String {
      let o = orders.map({$0.description}).joined(separator: ", ")
      return "\(ticker): \(bitcoinValue.summary) BTC \(o)"
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
}

enum BuySell: String {
    case buy
    case sell
}

struct Order: CustomStringConvertible {
  let price: Double
  let amount: Double
  let type: BuySell
  var proceeds: Double {
      return price * amount
  }
  var description: String {
      return "\(type) \(amount.summary) for \(proceeds.summary) BTC"
  }
}

struct Portfolio: CustomStringConvertible {
  let holdings: [Holding]
  let btcPrice: Double?
  private func total() -> Double {
      return holdings.reduce(0, { sum, holding in
          return sum + holding.bitcoinValue
      })
  }
  var description: String {
      let sorted = holdings.sorted(by: { $0.ticker < $1.ticker })
      let all: [String] = sorted.map({$0.description})
      let 💰 = btcPrice != nil ? (btcPrice! * total()).dollars : ""
      return "\(all.joined(separator: "\n"))\nTotal: \(total().summary) BTC \(💰)"
  }
}
/*
class Holding {
    let ticker: String
    let amount: Double
    let name: String
    let threshold: Double
    let basis: Double
    var conversion: Double = 0
    var price: Double = 0
    func value() -> Double {
        return price * amount
    }
    func btcValue() -> Double {
        return conversion * amount
    }
    func gain() -> String {
        let gain = (conversion - basis) / basis
        return String(format: "%.1f", gain * 100) + "%"
    }

    init(key: String, amount: Double, name: String, threshold: Double, basis: Double) {
        self.key = key
        self.amount = amount
        self.name = name
        self.threshold = threshold
        self.basis = basis
    }
}
*/
