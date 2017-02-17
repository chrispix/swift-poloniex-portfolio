
import Foundation
//import crypto

struct PoloniexRequest {
  let body: String
  let hash: String
  let keys: APIKeys
  var bodyData: Data {
    return body.data(using: .utf8)!
  }
  var urlRequest: URLRequest {
      var request = URLRequest(url: tradingURL)
      request.setValue(keys.key, forHTTPHeaderField: "Key")
      request.setValue(hash, forHTTPHeaderField: "Sign")
      request.httpBody = bodyData
      request.httpMethod = "POST"
      return request
  }
  let tradingURL = URL(string: "https://poloniex.com/tradingApi")!

  init(params: [String: String], keys: APIKeys) {
    self.keys = keys

    let nonce = Int64(Date().timeIntervalSince1970 * 1000)
    var queryItems = [URLQueryItem]()
    for (key, value) in params {
      queryItems.append(URLQueryItem(name: key, value: value))
    }
    queryItems.append(URLQueryItem(name: "nonce", value: "\(nonce)"))
    var components = URLComponents()
    components.queryItems = queryItems
    let body = components.query!
    let hash = body.hmac(algorithm: HMACAlgorithm.SHA512, key: keys.secret)

    self.body = body
    self.hash = hash
  }
}
