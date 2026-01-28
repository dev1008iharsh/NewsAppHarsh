//
//  NewsViewModel.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import Foundation
import GoogleMobileAds

final class NewsViewModel {
    
    // MARK: - Properties
    
    var newsDataModel: NewsResponse?
    
    /// **Raw Data:** Stores only Articles (Used for Core Data / Math)
    var articles = [Article]()
    
    /// **Display Data:** Stores Mixed Content (News + Ads) for TableView
    var feedItems = [FeedItem]()
    
    /// **Request Task:** To handle cancellation of previous requests
    private var currentTask: URLSessionDataTask?

    // MARK: - Event Handling
    enum Event {
        case loading
        case stopLoading
        case dataLoaded
        case network(Error?)
    }

    var eventHandler: ((_ event: Event) -> Void)?

    // MARK: - API Fetch Logic
    
    func fetchNewsApi(page: Int) {
        
        // 1. Cancel previous running task (Fast Scroll Fix 🚀)
        currentTask?.cancel()
        
        eventHandler?(.loading)

        // 2. Fetch Data
        currentTask = ApiManager.shared.request(modelType: NewsResponse.self, type: NewsEndPointItem.news(page: page)) { [weak self] response in
            guard let self = self else { return }
            
            self.currentTask = nil // Task completed
            self.eventHandler?(.stopLoading)

            switch response {
            case let .success(newsData):
                self.newsDataModel = newsData
                let newArticles = newsData.articles ?? []
                
                // 3. Update Raw Data
                if page == 1 {
                    self.articles = newArticles
                } else {
                    self.articles.append(contentsOf: newArticles)
                }
                
                // 4. Process Feed (Merge Ads + News)
                // We assume Online mode when fetching API
                self.processFeed(newArticles: newArticles, isPagination: page > 1, mode: .online)

                self.eventHandler?(.dataLoaded)

            case let .failure(error):
                // Ignore cancellation errors
                if (error as NSError).code != NSURLErrorCancelled {
                    self.eventHandler?(.network(error))
                }
            }
        }
    }
    
    // MARK: - Feed Processing Logic (The Brains 🧠)
    
    /// Merges Ads into the Article list based on the configured interval.
    func processFeed(newArticles: [Article], isPagination: Bool, mode: FeedMode) {
        
        // If not pagination (Pull to Refresh), clear everything
        if !isPagination {
            feedItems.removeAll()
        }
        
        // Calculate where to start the 'Math' for Ad placement
        // If pagination, we continue counting from the last item
        var currentDisplayCount = feedItems.count
        
        for article in newArticles {
            
            // A. Add Article
            feedItems.append(.news(article))
            currentDisplayCount += 1
            
            // B. Offline Check: Skip ads if offline
            if mode == .offline { continue }
            
            // C. Ad Injection Logic
            // If we hit the interval (e.g., every 5th item), try to inject an Ad
            if currentDisplayCount % FeedConfig.adInterval == 0 {
                
                // Fetch next ad from the Circular Pool
                if let nativeAd = GoogleAdClassManager.shared.getNextNativeAd() {
                    feedItems.append(.ad(nativeAd))
                    // Note: We don't increment 'currentDisplayCount' here
                    // because we usually count content items (Articles) for ad intervals.
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Re-generates the feed. Useful when switching from Offline -> Online.
    func refreshFeed(mode: FeedMode) {
        // Clear display list
        feedItems.removeAll()
        
        // Re-process all existing articles with the new mode
        processFeed(newArticles: articles, isPagination: false, mode: mode)
    }
}
