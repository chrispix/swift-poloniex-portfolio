
import Foundation

public struct HoldingsLoader {
  public static func loadHoldings(_ keys: APIKeys) -> [Holding] {
    let session = URLSession(configuration: URLSessionConfiguration.default)
    let poloniexRequest = PoloniexRequest(command: "/balances", params: [:], keys: keys)
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
            let coins: [[AnyHashable: Any]] = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [[AnyHashable: Any]]
            for coin in coins {
                guard let ticker = coin["currencySymbol"] as? String,
                    let balance = coin["total"] as? String,
                    let available = coin["available"] as? String,
                    let bal = Double(balance),
                    let avail = Double(available)
                    else { continue }
                let price: Double
                if ticker == "BTC" {
                    price = 1
                } else {
                    guard let market = coin["BitcoinMarket"] as? [AnyHashable: Any],
                        let bitcoinPrice = market["Ask"] as? Double else { continue }
                    price = bitcoinPrice
                }
                let holding = Holding(ticker: ticker, bitcoinPrice: price, availableAmount: avail, onOrders: bal - avail)
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

/*
 {
 Balance =     {
 AccountId = 900874;
 AutoSell = "<null>";
 Available = "9.37629596";
 Balance = "22.87029596";
 CryptoAddress = Ld5BjnPP9qmjjKUKfXSnn46qsTKdPgSFkD;
 Currency = LTC;
 Pending = 0;
 Requested = 0;
 Updated = "<null>";
 Uuid = "9821c6b9-386a-4ae3-847b-318e442fee39";
 };
 BitcoinMarket =     {
 Ask = "0.009339";
 BaseVolume = "1389.3326494";
 Bid = "0.009330730000000001";
 Created = "2014-02-13T00:00:00";
 High = "0.00963";
 Last = "0.009339999999999999";
 Low = "0.0091";
 MarketName = "BTC-LTC";
 OpenBuyOrders = 4895;
 OpenSellOrders = 7807;
 PrevDay = "0.009467369999999999";
 TimeStamp = "2017-11-28T07:55:13.45";
 Volume = "148615.97339712";
 };
 Currency =     {
 BaseAddress = LhyLNfBkoKshT7R8Pce6vkB9T2cP2o84hx;
 CoinType = BITCOIN;
 Currency = LTC;
 CurrencyLong = Litecoin;
 IsActive = 1;
 MinConfirmation = 6;
 Notice = "<null>";
 TxFee = "0.01";
 };
 EthereumMarket =     {
 Ask = "0.195";
 BaseVolume = "2039.77945198";
 Bid = "0.19400313";
 Created = "2017-06-25T03:06:46.83";
 High = "0.19747274";
 Last = "0.19400302";
 Low = "0.18603288";
 MarketName = "ETH-LTC";
 OpenBuyOrders = 243;
 OpenSellOrders = 425;
 PrevDay = "0.18730054";
 TimeStamp = "2017-11-28T07:53:11.613";
 Volume = "10713.80867706";
 };
 FiatMarket = "<null>";
 }
 */
