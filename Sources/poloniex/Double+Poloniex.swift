
import Foundation

extension Double {
    var dollars: String {
        return String(format: "$%.1f", self)
    }

    var summary: String {
        return String(format: "%.2f", self)
    }
}
