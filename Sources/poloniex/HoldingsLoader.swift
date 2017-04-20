
import Foundation

public struct HoldingsLoader {
  public static func loadHoldings(_ keys: APIKeys) -> [Holding] {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    let poloniexRequest = PoloniexRequest(params: ["command": "returnCompleteBalances"], keys: keys)
    let request = poloniexRequest.urlRequest

    var finished = false

    var holdings = [Holding]()

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
            for (key, value) in dict {
                guard let key = key as? String, let value = value as? [AnyHashable: Any?],
                let amount = value["available"] as? String,
                let available = Double(amount),
                let bitcoinValue = value["btcValue"] as? String,
                let bits = Double(bitcoinValue), bits > 0 else { continue }
                let onOrders: Double = {
                    guard let out = value["onOrders"] as? String else { return 0 }
                    return Double(out) ?? 0
                }()

                let holding = Holding(ticker: key, bitcoinValue: bits, availableAmount: available, onOrders: onOrders)
                holdings.append(holding)
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
}
