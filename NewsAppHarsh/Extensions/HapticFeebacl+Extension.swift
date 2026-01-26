//
//  HapticFeebacl+Extension.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import UIKit
extension UIImpactFeedbackGenerator {
    enum ImpactStyle {
        case lightImpact, mediumImpact, heavyImpact
    }

    convenience init(style: ImpactStyle) {
        switch style {
        case .lightImpact:
            self.init(style: .light)
        case .mediumImpact:
            self.init(style: .medium)
        case .heavyImpact:
            self.init(style: .heavy)
        }
    }

    func impact() {
        prepare()
        impactOccurred()
    }
}
