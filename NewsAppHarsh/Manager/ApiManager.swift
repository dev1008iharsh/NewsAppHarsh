//
//  NewsAppHarsh.swift
//  SwiftApiMVVM
//
//  Created by My Mac Mini HARSH DARJI on 08/01/24.
//  https://github.com/dev1008iharsh?tab=repositories
// 467ec62e59864e5ab75a84be5287afee News API key
//703c30bbb6ed4fd09a8499b2a7726b31


import Foundation
import UIKit

// MARK: - Error Handling
enum DataError: Error {
    case invalidResponse
    case invalidURL
    case invalidData
    case network(Error?)
}

// Pro Tip: Handler must be Sendable for strict concurrency (iOS 26)
typealias Handler<T> = @Sendable (Result<T, DataError>) -> Void

final class ApiManager: Sendable {
    static let shared = ApiManager()

    private init() {}

    // Common Headers logic
    var commonHeaders: [String: String] {
        return ["Authorization": "Bearer \(Constant.authKey)"]
    }

    // MARK: - Generic Request

    // 👇 ફેરફાર જુઓ: અહી આપણે Return Type ઉમેર્યું છે -> URLSessionDataTask?
    // @discardableResult નો ઉપયોગ એટલે કર્યો કે જો કોઈ વાર આપણે task store ના કરવું હોય તો warning ના આવે.
    
    @discardableResult
    func request<T: Codable & Sendable>(
        modelType: T.Type,
        type: EndPointType,
        completion: @escaping Handler<T>
    ) -> URLSessionDataTask? {
        
        guard let url = type.url else {
            completion(.failure(.invalidURL))
            return nil // 👈 જો URL ખોટું હોય તો nil return થશે
        }

        var request = URLRequest(url: url)
        request.httpMethod = type.method.rawValue
        request.allHTTPHeaderFields = type.headers

        // Body encoding logic
        if let parameters = type.body {
            request.httpBody = try? JSONEncoder().encode(parameters)
        }

        print("🟢🟢🟢 API Calling : ", request.url ?? "no url")

        // 👇 Data Task ને એક variable માં store કર્યો
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            guard let data = data, error == nil else {
                completion(.failure(.invalidData))
                return
            }

            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                let model = try JSONDecoder().decode(T.self, from: data)
                completion(.success(model))
            } catch {
                completion(.failure(.network(error)))
            }
        }
        
        task.resume() // Task ને start કર્યું
        return task   // 👈 અને છેલ્લે Task ને return કર્યું
    }
}
