
import Foundation

/*
 [{ "globalTradeID": 25129732, "tradeID": "6325758", "date": "2016-04-05 08:08:40", "rate": "0.02565498", "amount": "0.10000000", "total": "0.00256549", "fee": "0.00200000", "orderNumber": "34225313575", "type": "sell", "category": "exchange" }, { "globalTradeID": 25129628, "tradeID": "6325741", "date": "2016-04-05 08:07:55", "rate": "0.02565499", "amount": "0.10000000", "total": "0.00256549", "fee": "0.00200000", "orderNumber": "34225195693", "type": "buy", "category": "exchange" }, ... ]
 */
class HistoryLoader {
    private static let dateParser: DateFormatter = {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
        return parser
    }()

    static func loadOrders(_ holding: Holding, keys: APIKeys) -> [ExecutedOrder] {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let poloniexRequest = PoloniexRequest(params: ["command": "returnTradeHistory", "currencyPair": holding.bitcoinMarketKey, "start": "0", "end": "\(Date().timeIntervalSince1970)"], keys: keys)
        let request = poloniexRequest.urlRequest

        var finished = false

        var orders = [ExecutedOrder]()

        let historyTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
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
                let orderDicts: [[AnyHashable: Any?]] = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [[AnyHashable: Any?]]
                for order in orderDicts {
                    guard let typeString = order["type"] as? String,
                        let type = BuySell(rawValue: typeString),
                        let amount = JSONHelper.double(fromJsonObject: order["amount"] as? String),
                        let price = JSONHelper.double(fromJsonObject: order["rate"] as? String),
                        let total = JSONHelper.double(fromJsonObject: order["total"] as? String),
                        let fee = JSONHelper.double(fromJsonObject: order["fee"] as? String),
                        let dateString = order["date"] as? String,
                        let date = dateParser.date(from: dateString)
                        else { continue }
                    let thisOrder = ExecutedOrder(price: price, amount: amount, type: type, fee: fee, total: total, date: date)
                    orders.append(thisOrder)
                }
            } catch {
                print("couldn't decode JSON")
                finished = true
                return
            }

            finished = true
        })

        historyTask.resume()

        while(!finished) {}

        return orders
    }

}
