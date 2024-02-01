//
//  NewsAppHarsh.swift
//  SwiftApiMVVM
//
//  Created by My Mac Mini HARSH DARJI on 08/01/24.
//  https://github.com/dev1008iharsh?tab=repositories

import Foundation
 
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
        return ["Authorization" : "Bearer \(Constant.shared.authKey)"]
    }
    
}
 
