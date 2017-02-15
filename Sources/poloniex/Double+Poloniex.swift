
import Foundation

extension Double {
    var dollars: String {
        return String(format: "$%.1f", self)
    }

    var summary: String {
        return String(format: "%.2f", self)
    }

    var rounded: String {
        return String(format: "%.0f", self)
    }

    var threeSignificant: String {
        var temp = self
        while temp <= 100 {
            temp *= 10
        }
        return temp.rounded
    }
}
