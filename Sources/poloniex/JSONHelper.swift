
struct JSONHelper {
    static func double(fromJsonObject obj: String?) -> Double? {
        guard let string = obj, let double = Double(string) else { return nil }
        return double
    }
}
