
struct JSONHelper {
    static func double(fromJsonObject obj: AnyObject?) -> Double? {
        guard let string = obj as? String, let double = Double(string) else { return nil }
        return double
    }
}
