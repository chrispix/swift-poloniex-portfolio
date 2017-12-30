
import Foundation

// endpoint list: https://github.com/ericsomdahl/python-bittrex/issues/35#issuecomment-326191279

public struct OrdersLoader {
  public static func loadOrders(_ holdings: [Holding], keys: APIKeys) -> [Holding] {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    let poloniexRequest = PoloniexRequest(command: "/key/orders/getopenorders", params: [:], keys: keys)
    let request = poloniexRequest.urlRequest

    var finished = false

    var holdings = holdings

    let holdingsTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
        guard let data = data, let responseBody = String(data: data, encoding: .utf8) else {
            print("couldn't decode data")
            finished = true
            return
        }

        guard error == nil else {
            print("error response")
            finished = true
            return
        }

        guard !responseBody.isEmpty else {
            print("empty response")
            finished = true
            return
        }

        do {
            let dict: [AnyHashable: Any?] = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [AnyHashable: Any?]
            let orders = dict["result"] as! [[AnyHashable: Any]]
            for order in orders {
                print(order)
                guard let typeString = order["OrderType"] as? String,
                    let market = order["Exchange"] as? String,
                    let type = BuySell(rawValue: typeString),
                    let amount = order["Quantity"] as? Double,
                    amount > 0
                else { continue }
                let thisOrder = Order(price: 0, amount: amount, type: type)
                holdings = addOrder(thisOrder, market: market, to: holdings)
            }
        } catch {
            print("couldn't decode JSON")
            finished = true
            return
        }

        holdings = holdings.filter({ $0.amount > 0 || $0.orders.count > 0 })

        finished = true
    })

    holdingsTask.resume()

    while(!finished) {}

    return holdings
  }

  private static func addOrder(_ order: Order, market: String, to holdings: [Holding]) -> [Holding] {
      if holdings.filter({ $0.bitcoinMarketKey == market }).isEmpty, let ticker = Holding.ticker(fromBitcoinMarketKey: market) {
          // we have no holding for this currency
        var holding = Holding(ticker: ticker, bitcoinPrice: 0, availableAmount: 0, onOrders: 0)
          holding.addOrder(order)
          var holdings = holdings
          holdings.append(holding)
          return holdings
      } else {
          return holdings.map({ holding in
              if holding.bitcoinMarketKey == market {
                  var holding = holding
                  holding.addOrder(order)
                  return holding
              } else {
                  return holding
              }
          })
      }
  }
}
