
import Foundation

public struct QuotesLoader {
  public static func loadBTCPrice() -> Double? {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    let url = URL(string: "http://api.coindesk.com/v1/bpi/currentprice.json")!
    let request = URLRequest(url: url)
    var finished = false

    var btcPrice: Double?

    let quotesTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
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
            guard let bpi = dict["bpi"] as? [AnyHashable: Any?],
                let bitcoinToUSD = bpi["USD"] as? [AnyHashable: Any?],
                let bitcoinPrice = bitcoinToUSD["rate_float"] as? Double else { return }
            btcPrice = bitcoinPrice
        } catch {
            print("couldn't decode JSON")
            finished = true
            return
        }

        finished = true
    })

    quotesTask.resume()

    while(!finished) {}

    return btcPrice
  }

}
