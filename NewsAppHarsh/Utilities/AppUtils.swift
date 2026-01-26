//
//  AppUtils.swift
//  NewsAppHarsh
//
//  Created by Harsh on 25/01/26.
//

import UIKit

final class AppUtils {
    
    // Pro Tip: Singleton with private init is a must
    static let shared = AppUtils()
    private init() {}
    
    // Formatting handles efficiency by reusing the formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    func format(dateString: String, from: String, to: String) -> String? {
        dateFormatter.dateFormat = from
        guard let date = dateFormatter.date(from: dateString) else { return nil }
        dateFormatter.dateFormat = to
        return dateFormatter.string(from: date)
    }
}
