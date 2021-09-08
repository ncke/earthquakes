//
//  Double+Rounding.swift
//  Earthquake
//
//  Created by Nick on 08/09/2021.
//

import Foundation

extension Double {

    func rounded(dp: Int) -> Double {
        let multiplier = pow(10, Double(dp))
        let rounded = (self * multiplier).rounded() / multiplier
        return rounded
    }

    var to1dp: Double { self.rounded(dp: 1) }

    var to2dp: Double { self.rounded(dp: 2) }

}
