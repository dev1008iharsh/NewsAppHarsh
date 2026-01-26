//
//  NewsAppHarsh.swift
//  SwiftApiMVVM
//
//  Created by My Mac Mini  HARSH DARJI on 08/01/24.
//  https://github.com/dev1008iharsh?tab=repositories

import Foundation

enum HttpMehtod: String {
    case get = "GET"
    case post = "POST"
}

protocol EndPointType {
    var path: String { get }
    var baseUrl: String { get }
    var url: URL? { get }
    var page: Int { get }
    var method: HttpMehtod { get }
    var body: Encodable? { get }
    var headers: [String: String] { get }
}
