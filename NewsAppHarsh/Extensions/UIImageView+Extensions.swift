//
//  UIImageView+Extensions.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import UIKit

// Runtime Association Keys
private var imageURLKey: UInt8 = 0
private var dataTaskKey: UInt8 = 0

extension UIImageView {
    // 1. Store current URL string to check validity later
    private var currentURL: String? {
        get { return objc_getAssociatedObject(self, &imageURLKey) as? String }
        set { objc_setAssociatedObject(self, &imageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // 2. Store current DataTask to cancel old downloads
    private var currentTask: URLSessionDataTask? {
        get { return objc_getAssociatedObject(self, &dataTaskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &dataTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - Public Function to Call

    func downloadImage(fromURL url: String, placeholder: UIImage? = UIImage(named: "placeholder")) {
        // Step A: Cancel previous download if running (Saves Data & Fixes Flickering)
        currentTask?.cancel()

        // Step B: Set Placeholder immediately
        image = placeholder

        // Step C: Save the new URL we are asking for
        currentURL = url

        // Step D: Request Image
        let task = ImageLoader.shared.loadImage(from: url) { [weak self] loadedImage in
            guard let self = self else { return }

            // 🔥 CRITICAL CHECK:
            // ઈમેજ ડાઉનલોડ થઈ ગઈ, પણ શું આ સેલ હજુ એ જ URL માંગે છે?
            // જો સેલ રી-યુઝ થઈ ગયો હશે, તો currentURL બદલાઈ ગયો હશે.
            if self.currentURL == url {
                self.image = loadedImage
            } else {
                // print("⚠️ Ignored old image for reused cell")
            }
        }

        // Step E: Save the task so we can cancel it later
        currentTask = task
    }
}
