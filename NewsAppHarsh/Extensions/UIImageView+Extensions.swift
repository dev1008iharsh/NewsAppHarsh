//
//  UIImageView+Extensions.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import UIKit
import UIKit

// Runtime Association Keys
private var imageURLKey: UInt8 = 0
private var dataTaskKey: UInt8 = 0

extension UIImageView {
    
    // Properties to track state
    private var currentURL: String? {
        get { return objc_getAssociatedObject(self, &imageURLKey) as? String }
        set { objc_setAssociatedObject(self, &imageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var currentTask: URLSessionDataTask? {
        get { return objc_getAssociatedObject(self, &dataTaskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &dataTaskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Public Functions
    
    // ✅ NEW: Explicit Cancel Function
    func cancelDownload() {
        currentTask?.cancel()
        currentTask = nil
    }

    func downloadImage(fromURL url: String, placeholder: UIImage? = UIImage(named: "placeholder")) {
        
        // 1. Cancel active download immediately
        cancelDownload()
        
        // 2. Set Placeholder & Store URL
        self.image = placeholder
        self.currentURL = url
        
        // 3. Request Image
        let task = ImageLoader.shared.loadImage(from: url) { [weak self] loadedImage in
            guard let self = self else { return }
            
            // ✅ Ensure UI update is on Main Thread
            DispatchQueue.main.async {
                
                // 🔥 Critical Check: Cell URL match?
                if self.currentURL == url {
                    
                    // ✅ Safety Check: Don't set NIL if download failed.
                    // Keep the placeholder if loadedImage is nil.
                    if let image = loadedImage {
                        self.image = image
                    } else {
                        // Optional: Set an 'error' image if needed
                        // self.image = UIImage(named: "error_image")
                    }
                }
            }
        }
        
        // 4. Save Task
        self.currentTask = task
    }
}
