
import Foundation

public struct HoldingsLoader {
  public static func loadHoldings(_ keys: APIKeys) -> [Holding] {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    let poloniexRequest = PoloniexRequest(command: "/account/getbalances", params: [:], keys: keys)
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
            let dict: [AnyHashable: Any] = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [AnyHashable: Any]
            let coins = dict["result"] as! [[AnyHashable: Any]]
            for coin in coins {
                guard
                    let key = coin["Currency"] as? String,
                    let available = coin["Available"] as? Double,
//                    let pending = coin["Pending"] as? Double,
                    let balance = coin["Balance"] as? Double
                    else { continue }
                let holding = Holding(ticker: key, availableAmount: available, onOrders: balance - available)
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
