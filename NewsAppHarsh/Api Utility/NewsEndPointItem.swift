//
//  NewsAppHarsh.swift
//  SwiftApiMVVM
//
//  Created by My Mac Mini  HARSH DARJI on 09/01/24.
//  https://github.com/dev1008iharsh?tab=repositories
// https://newsapi.org/v2/top-headlines?country=in&apiKey=467ec62e59864e5ab75a84be5287afee

import Foundation

enum NewsEndPointItem {
    case news(page: Int) // get news
}

extension NewsEndPointItem: EndPointType {
    var body: Encodable? {
        switch self {
        case .news:
            return nil
        }
    }

    var headers: [String: String] {
        return ApiManager.shared.commonHeaders
    }

    var path: String {
        switch self {
        case .news:
            return "v2/everything?q=cricket&pageSize=20"
            //https://newsapi.org/v2/everything?q=india&apiKey=467ec62e59864e5ab75a84be5287afee
            // we are passing api key in commanHeaders header bear token and it is working
        }
    }

    var page: Int {
        switch self {
        case let .news(page):
            return page
        }
    }

    var baseUrl: String {
        // we can also direct return we have same url for whole project
        switch self {
        case .news:
            return "https://newsapi.org/"
        }
    }

    var url: URL? {
        return URL(string: "\(baseUrl)\(path)&page=\(page)")
    }

    var method: HttpMehtod {
        switch self {
        case .news:
            return .get
        }
    }
}
