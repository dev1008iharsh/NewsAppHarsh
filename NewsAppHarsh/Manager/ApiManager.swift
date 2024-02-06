//
//  NewsAppHarsh.swift
//  SwiftApiMVVM
//
//  Created by My Mac Mini HARSH DARJI on 08/01/24.
//  https://github.com/dev1008iharsh?tab=repositories

import Foundation
import UIKit

enum DataError : Error {
    case invalidRepsonse
    case invalidURL
    case invalidData
    case network(Error?)
}

typealias Handler<T> = (Result<T, DataError>) -> Void

// singleton class
class ApiManager{
    
    static let shared = ApiManager()
    
    let cache = NSCache<NSString, UIImage>()
    
    private init(){}
    
    
    // get and post data within one api using generics
    func request< T:Codable >(modelType : T.Type, type : EndPointType, completion : @escaping Handler<T>) {
        //guard let url = URL(string: Constant.API.productURl) else { - ani jagya ae durect url enum manthi lese
        guard let url = type.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = type.method.rawValue
        
        // ahiya guard etla mate use nathi karelu kyarey body na hoy to return thay to agl nu function call nathay
        if let parameters = type.body{
            request.httpBody = try? JSONEncoder().encode(parameters)
        }
        
        request.allHTTPHeaderFields = type.headers
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            //guard let data = data else { return } avu be var data lakhvani jarur nathi
            guard let data, error == nil else {
                completion(.failure(.invalidData))
                return
            }
            
            guard let response = response as? HTTPURLResponse,
                  200 ... 299 ~=  response.statusCode else {
                completion(.failure(.invalidRepsonse))
                return
            }
            
            // Array      - [Product].self
            // Dictionary - Product.self
            //JSONDecoder() - Data ne model ma convert karse
            
            do{
                let model = try JSONDecoder().decode(modelType.self, from: data)
                completion(.success(model))
            }catch{
                completion(.failure(.network(error)))
            }
            
            
        }.resume()
    }
    
    
    static var commanHeaders : [String : String]{
        return ["Authorization" : "Bearer \(Constant.authKey)"]
    }
    
    func downloadImage(from urlString: String, completed: @escaping (UIImage?) -> Void) {
        // Create cache key
        let cacheKey = NSString(string: urlString)
        
        // Check if image is already in cache
        if let image = cache.object(forKey: cacheKey) {
            completed(image)
            return
        }
        
        // Check if URL is valid
        guard let url = URL(string: urlString) else {
            completed(nil)
            return
        }
        
        // Perform URL session task
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for errors and valid HTTP response
            guard error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data, let image = UIImage(data: data) else {
                completed(nil)
                return
            }
            
            // Store image in cache and call completion handler
            self.cache.setObject(image, forKey: cacheKey)
            completed(image)
        }
        
        // Start the task
        task.resume()
    }
}

