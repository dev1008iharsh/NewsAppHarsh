//
//  NewsAppHarsh.swift
//  SwiftApiMVVM
//
//  Created by My Mac Mini HARSH DARJI on 08/01/24.
//  https://github.com/dev1008iharsh?tab=repositories
// 467ec62e59864e5ab75a84be5287afee News API key
import Foundation
import UIKit

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

    func request<T: Codable & Sendable>(
        modelType: T.Type,
        type: EndPointType,
        completion: @escaping Handler<T>
    ) {
        guard let url = type.url else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = type.method.rawValue
        request.allHTTPHeaderFields = type.headers

        if let parameters = type.body {
            request.httpBody = try? JSONEncoder().encode(parameters)
        }

        print("🟢🟢🟢 API Calling : ",request.url ?? "no url")
        // Data Task
        URLSession.shared.dataTask(with: request) { data, response, error in

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
        }.resume()
    }
}
