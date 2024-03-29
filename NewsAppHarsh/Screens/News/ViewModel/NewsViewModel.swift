//
//  NewsViewModel.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import Foundation

final class NewsViewModel{
    
    var newsDataModel : NewsModel?
    var articles = [Articles]()
    
    var eventHandler : ((_ event : Event) -> Void)?
    
    func fetchNewsApi(page : Int){
        
        eventHandler?(.loading)
        
        ApiManager.shared.request(modelType: NewsModel.self, type: NewsEndPointItem.news(page: page)) { [ weak self ] response in
            
            guard let self else { return }
            
            eventHandler?(.stopLoading)
            
            switch response{
            case .success(let newsData):
                
                self.newsDataModel = newsData
                self.articles = (newsData.articles ?? [])
                eventHandler?(.dataLoaded)
                
            case .failure(let error):
                
                print(error)
                eventHandler?(.network(error))
                
            }
        }
    }
}


extension NewsViewModel{
    enum Event {
        case loading
        case stopLoading
        case dataLoaded
        case network(Error?)
    }
    
}
