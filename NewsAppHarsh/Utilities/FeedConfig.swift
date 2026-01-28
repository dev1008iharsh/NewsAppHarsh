//
//  FeedConfig.swift
//  NewsAppHarsh
//
//  Created by Harsh on 28/01/26.
//

import Foundation
import GoogleMobileAds

// MARK: - Feed Configuration
struct FeedConfig {
    static let adInterval = 5 // Show Ad after every 5 news items
    static let maxAdPoolSize = 15 // Stop fetching new ads after we have 15 in memory(RAM saver)
    static let adBatchSize = 3 // How many ads gets from google server at a time
}

// MARK: - Feed Mode
enum FeedMode {
    case online
    case offline
}

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
