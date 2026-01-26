//
//  HapticManager.swift
//  NewsAppHarsh
//
//  Created by Harsh on 25/01/26.
//

import UIKit

final class HapticManager {
    static let shared = HapticManager()

    // Pro Tip: Keep generators in memory to avoid lag
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {}

    enum HapticStyle {
        case light, medium, heavy, selection, success, error, warning
    }

    func play(_ style: HapticStyle) {
        switch style {
        case .light:
            lightGenerator.prepare()
            lightGenerator.impactOccurred()
        case .medium:
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred()
        case .heavy:
            heavyGenerator.prepare()
            heavyGenerator.impactOccurred()
        case .selection:
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        case .success:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        case .error:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.error)
        case .warning:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.warning)
        }
    }
}
