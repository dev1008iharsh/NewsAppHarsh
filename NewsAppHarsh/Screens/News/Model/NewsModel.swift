//
//  NewsData.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import Foundation

import Foundation

// MARK: - Main Response

struct NewsResponse: Codable {
    let status: String?
    let totalResults: Int?
    let articles: [Article]?
}

import Foundation

// MARK: - Article Model

// Added 'Equatable' to compare two articles easily
struct Article: Codable, Sendable, Equatable {
    let author: String?
    let title: String?
    let descriptionText: String?
    let articleUrl: String?
    let imageUrl: String?
    let publishedAt: String?
    let content: String?

    // JSON Keys Mapping
    enum CodingKeys: String, CodingKey {
        case author, title, content, publishedAt
        case descriptionText = "description"
        case articleUrl = "url"
        case imageUrl = "urlToImage"
    }

    // Equatable Logic: (Swift automatic rite badhu compare kari le chhe, pan explicit lakhiye to vadhu saru)
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.articleUrl == rhs.articleUrl &&
            lhs.publishedAt == rhs.publishedAt
    }
}
