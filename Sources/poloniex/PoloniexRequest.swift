
import Foundation
import Crypto

struct PoloniexRequest {
    private let hash: String
    private let timestamp: String
    private let keys: APIKeys
    private let url: URL
    private let method: String = "GET"
    private let preSignHash: String
    private let command: String

    var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.setValue(keys.key, forHTTPHeaderField: "Api-Key")
        request.setValue(timestamp, forHTTPHeaderField: "Api-Timestamp")
        request.setValue(hash, forHTTPHeaderField: "Api-Content-Hash")
        request.setValue(preSignHash, forHTTPHeaderField: "Api-Signature")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpMethod = method
        return request
    }
    let baseURL = "https://api.bittrex.com/v3"

    init(command: String, params: [String: String], keys: APIKeys) {
        self.keys = keys
        self.command = command
        let now: TimeInterval = Date().timeIntervalSince1970
        self.timestamp = String(Int64((now * 1000.0).rounded()))

        let fullURL = URL(string: baseURL + command)!
        self.url = fullURL

        let key = SymmetricKey(data: keys.secret.data(using: .utf8)!)
        let urlData = "".data(using: .utf8)!
        let hashed = SHA512.hash(data: urlData)

        let theHash = hashed.makeIterator().map({ String(format: "%02hhx", $0) }).joined()
        self.hash = theHash

        let presign = [timestamp, fullURL.absoluteString, method, theHash].joined()
        let presignData = presign.data(using: .utf8)!
        let presignHmac = HMAC<SHA512>.authenticationCode(for: presignData, using: key)
        let presignHash = presignHmac.makeIterator().map({ String(format: "%02hhx", $0) }).joined()
        self.preSignHash = presignHash
    }
}

/*
https://api.bittrex.com/v3/balances
▿ url : Optional<URL>
▿ some : https://api.bittrex.com/v3/balances
- _url : https://api.bittrex.com/v3/balances
- cachePolicy : 0
- timeoutInterval : 60.0
- mainDocumentURL : nil
- networkServiceType : __C.NSURLRequestNetworkServiceType
- allowsCellularAccess : true
▿ httpMethod : Optional<String>
- some : "GET"
▿ allHTTPHeaderFields : Optional<Dictionary<String, String>>
▿ some : 6 elements
▿ 0 : 2 elements
- key : "Api-Key"
- value : "5f19f64ccbb348ef8000cd52f34ff1c1"
▿ 1 : 2 elements
- key : "Api-Content-Hash"
- value : "214fbdc6e9020a8ad6ffd21b22942399850e0d990b5a411ee4831e3201a8bc0697c1fe8e946d8b6305b8e31aee1344c49a06275507177bb92b70376a0c41a363"
▿ 2 : 2 elements
- key : "Api-Timestamp"
- value : "1580855965987"
▿ 3 : 2 elements
- key : "Content-Type"
- value : "application/json"
▿ 4 : 2 elements
- key : "Api-Signature"
- value : "5bfb0c0e9c3e66c169cdb99ce96926828cdc35bad6d04033387862beb980940fd392de16c3dc768d6f28dc7fbbbc3f9e7c8d72b6e797062bcd829eba4b3004b9"
- httpBody : nil
- httpBodyStream : nil
- httpShouldHandleCookies : true
- httpShouldUsePipelining : false
*/
