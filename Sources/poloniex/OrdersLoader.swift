
import Foundation

struct OrdersLoader {
  static func loadOrders(_ holdings: [Holding], keys: APIKeys) -> [Holding] {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    let poloniexRequest = PoloniexRequest(params: ["command": "returnOpenOrders", "currencyPair": "all"], keys: keys)
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
            let dict: [String: AnyObject] = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [String: AnyObject]
            for (market, orders) in dict {
                guard let orders = orders as? [[String: AnyObject]],
                orders.count > 0 else { continue }
                for order in orders {
                    guard let typeString = order["type"] as? String,
                        let type = BuySell(rawValue: typeString),
                        let amount = JSONHelper.double(fromJsonObject: order["amount"]),
                        let price = JSONHelper.double(fromJsonObject: order["rate"]) else { continue }
                    let thisOrder = Order(price: price, amount: amount, type: type)
                    holdings = addOrder(thisOrder, market: market, to: holdings)
                }
            }
        } catch {
            print("couldn't decode JSON")
            finished = true
            return
        }

        finished = true
    })

    holdingsTask.resume()

    while(!finished) {}

    return holdings
  }

  private static func addOrder(_ order: Order, market: String, to holdings: [Holding]) -> [Holding] {
      if holdings.filter({ $0.bitcoinMarketKey == market }).isEmpty, let ticker = Holding.ticker(fromBitcoinMarketKey: market) {
          // we have no holding for this currency
          var holding = Holding(ticker: ticker, bitcoinValue: 0, availableAmount: 0, onOrders: 0)
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
