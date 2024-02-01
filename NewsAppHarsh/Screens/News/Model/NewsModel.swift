//
//  NewsData.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import Foundation


struct NewsModel: Codable {
    
    let status: String?
    let totalResults: Int?
    let articles: [Articles]?
    
    private enum CodingKeys: String, CodingKey {
        case status = "status"
        case totalResults = "totalResults"
        case articles = "articles"
    }
    
}

struct Articles: Codable {
    
    //let source: Source?
    var author: String?
    var title: String?
    var myDescription: String?
    var url: String?
    var urlToImage: String?
    var publishedAt: String?
    var content: String?
    
    private enum CodingKeys: String, CodingKey {
        //case source = "source"
        case author = "author"
        case title = "title"
        case myDescription = "description"
        case url = "url"
        case urlToImage = "urlToImage"
        case publishedAt = "publishedAt"
        case content = "content"
    }
    
}
