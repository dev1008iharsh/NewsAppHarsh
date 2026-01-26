//
//  UITableView+Extension.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import UIKit

extension UITableView {
    /// Starts showing a loader at the bottom of the table view
    func showBottomLoader() {
        guard tableFooterView == nil else { return }

        let container = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 80))
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .systemGray
        indicator.center = container.center
        indicator.startAnimating()

        container.addSubview(indicator)
        tableFooterView = container
    }

    /// Hides the loader from the bottom of the table view
    func hideBottomLoader() {
        UIView.animate(withDuration: 0.2) {
            self.tableFooterView = nil
        }
    }
}
