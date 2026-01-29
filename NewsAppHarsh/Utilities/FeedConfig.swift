//
//  FeedConfig.swift
//  NewsAppHarsh
//
//  Created by Harsh on 28/01/26.
//

import Foundation
import GoogleMobileAds
 
// MARK: - Feed Item Wrapper
// This allows the TableView to handle both types safely
enum FeedItem: Equatable {
    case news(Article)
    case ad(NativeAd)
    
    // Equatable logic for DiffableDataSource or Comparisons
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        switch (lhs, rhs) {
        case (.news(let a), .news(let b)): return a == b
        case (.ad(let a), .ad(let b)): return a.headline == b.headline // Basic check
        default: return false
        }
    }
}
