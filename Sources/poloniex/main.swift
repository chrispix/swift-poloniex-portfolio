
import Foundation
import crypto

func showAlert(message: String) {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", "display notification \"\(message)\""]
    task.launch()
    task.waitUntilExit()
}

func alertHoldingsWithoutOrders(_ holdings: [Holding]) {
    holdings.forEach({ holding in
        if holding.orders.isEmpty && !holding.isBitcoin {
            showAlert(message: "No open orders for \(holding.ticker)")
        }
    })
}

let arguments = CommandLine.arguments

if arguments.count != 2 {
  print("USAGE: poloniex [path to API keys JSON]")
  exit(1)
}

let path = arguments[1]

if let keys = KeyLoader.loadKeys(path) {
    let holdings = HoldingsLoader.loadHoldings(keys)
    let holdingsWithOrders = OrdersLoader.loadOrders(holdings, keys: keys)
    alertHoldingsWithoutOrders(holdingsWithOrders)
    let btcPrice = QuotesLoader.loadBTCPrice()
    let portfolio = Portfolio(holdings: holdingsWithOrders, btcPrice: btcPrice)
    print(portfolio)
} else {
    print("Could not parse keys from \(path)")
}


/*
let coins = [bitcoin] + holdings

let sumValues: (Double, Holding) -> Double = { sum, coin in sum + coin.value() }
let sumConversions: (Double, Holding) -> Double = { sum, coin in sum + coin.btcValue() }

print("BTC: \(bitcoin.price.dollars)")
for coin in coins {
    print("\(coin.name): \(coin.value().dollars) \(coin.gain())")
}
print("Total: \(coins.reduce(0, sumValues).dollars) \(String(format: "%.2f", coins.reduce(0, sumConversions))) BTC")

for coin in coins where coin.btcValue() > coin.threshold {
    showAlert(message: "\(coin.name) value is \(coin.btcValue()) BTC!")
}
*/
