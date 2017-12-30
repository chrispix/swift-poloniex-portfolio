
import Foundation

extension Double {
    var dollars: String {
        return String(format: "$%.1f", self)
    }

    var summary: String {
        return String(format: "%.2f", self)
    }

    func precision(digits: Int) -> String {
        return String(format: "%.\(digits)f", self)
    }

    var rounded: String {
        return String(format: "%.0f", self)
    }

    var roundedPercent: String {
        return String(format: "%.0f%%", self * 100)
    }

    var threeSignificant: String {
        guard self > 0 else { return "0" }
        var temp = self
        while temp <= 100 {
            temp *= 10
        }
        return temp.rounded
    }
}
