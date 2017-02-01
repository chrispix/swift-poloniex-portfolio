
import Foundation

struct APIKeys {
    let key: String
    let secret: String
}

struct KeyLoader {
    static func loadKeys(_ path: String) -> APIKeys? {
        guard let data = FileManager.default.contents(atPath: path) else {
            print("Couldn't load keys JSON file")
            return nil
        }
        do {
            let dict: [String: AnyObject] = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [String: AnyObject]
            guard let apiKey = dict["API_KEY"] as? String, let secret = dict["API_SECRET"] as? String else {
                print("Couldn't find keys in JSON file")
                return nil
            }
            return APIKeys(key: apiKey, secret: secret)
        } catch {
            print("Couldn't parse keys JSON file")
            return nil
        }
    }
}
