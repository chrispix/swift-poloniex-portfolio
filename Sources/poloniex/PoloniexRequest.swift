
import Foundation
//import crypto

struct PoloniexRequest {
    let body: String
    let hash: String
    let keys: APIKeys
    let url: URL
    private let command: String
    var bodyData: Data {
        return body.data(using: .utf8)!
    }
    var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        //      request.setValue(keys.key, forHTTPHeaderField: "Key")
        request.setValue(hash, forHTTPHeaderField: "apisign")
        request.httpBody = bodyData
        request.httpMethod = "POST"
        return request
    }
    let baseURL = "https://bittrex.com/api/v2.0"

    init(command: String, params: [String: String], keys: APIKeys) {
        self.keys = keys
        self.command = command
        let fullURL = URL(string: baseURL + command)!

        let nonce = Date().timeIntervalSince1970 * 1000
//        let nonce = Int64(Date().timeIntervalSince1970 * 1000)
        var queryItems = [URLQueryItem]()
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        queryItems.append(URLQueryItem(name: "nonce", value: "\(nonce)"))
        queryItems.append(URLQueryItem(name: "apikey", value: "\(keys.key)"))
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        self.url = components.url!
        let hash = url.absoluteString.hmac(algorithm: HMACAlgorithm.SHA512, key: keys.secret)

        self.body = components.query!
        self.hash = hash
    }
}

