//
//  NewsViewModel.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import Foundation

final class NewsViewModel {
    var newsDataModel: NewsResponse?
    var articles = [Article]()

    // Enum for Event Handling
    enum Event {
        case loading
        case stopLoading
        case dataLoaded
        case network(Error?)
    }

    var eventHandler: ((_ event: Event) -> Void)?

    func fetchNewsApi(page: Int) {
        eventHandler?(.loading)

        ApiManager.shared.request(modelType: NewsResponse.self, type: NewsEndPointItem.news(page: page)) { [weak self] response in
            guard let self = self else { return }

            self.eventHandler?(.stopLoading)

            switch response {
            case let .success(newsData):
                self.newsDataModel = newsData
                self.articles = newsData.articles ?? []
                self.eventHandler?(.dataLoaded)

            case let .failure(error):
                self.eventHandler?(.network(error))
            }
        }
    }
}
