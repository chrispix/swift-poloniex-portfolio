
import Foundation

public struct PriceLoader {
    public static func loadPrices(_ holdings: [Holding], keys: APIKeys) -> [Holding] {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let poloniexRequest = PoloniexRequest(command: "/pub/Markets/GetMarketSummaries", params: [:], keys: keys)
        let request = poloniexRequest.urlRequest

        var finished = false

        var populatedHoldings = [Holding]()

        let tickersTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
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
                let markets = dict["result"] as! [[AnyHashable: Any]]
                var prices = [String: Double]()
                markets.forEach({ if let market = $0["MarketName"] as? String, let price = $0["Last"] as? Double { prices[market] = price }})
                for var holding in holdings {
                    guard let price = prices[holding.bitcoinMarketKey] else { continue }
//                    holding.bitcoinPrice = price
                    populatedHoldings.append(holding)
                }
            } catch {
                print("couldn't decode JSON")
                finished = true
                return
            }

            finished = true
        })

        tickersTask.resume()

        while(!finished) {}

        return populatedHoldings
    }
}

