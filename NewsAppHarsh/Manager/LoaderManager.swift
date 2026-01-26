//
//  LoaderManager.swift
//  NewsAppHarsh
//
//  Created by Harsh on 25/01/26.
//

import UIKit

@MainActor
final class LoaderManager {
    static let shared = LoaderManager()

    // Maintain state
    private var containerView: UIView?

    private init() {}

    // MARK: - Public Functions

    func startLoader(message: String? = nil) {
        // Prevent duplicate loaders
        guard containerView == nil else { return }

        // Get valid key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

        // 1. Main Container (Transparent - No Dimming)
        let mainContainer = UIView(frame: window.bounds)
        mainContainer.backgroundColor = .clear // Crucial: Keeps background fully visible
        mainContainer.isUserInteractionEnabled = true // Blocks touches while loading

        // 2. Central HUD (Small Box)
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let hudView = UIVisualEffectView(effect: blurEffect)
        hudView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        hudView.center = mainContainer.center
        hudView.layer.cornerRadius = 16
        hudView.clipsToBounds = true

        // 3. Activity Indicator
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        // Adjust position based on message existence
        indicator.center = CGPoint(x: hudView.bounds.midX, y: hudView.bounds.midY - (message == nil ? 0 : 10))
        indicator.startAnimating()

        hudView.contentView.addSubview(indicator)

        // 4. Message Label (Optional)
        if let text = message, !text.isEmpty {
            let label = UILabel(frame: CGRect(x: 5, y: 70, width: 90, height: 25))
            label.numberOfLines = 1
            label.text = text
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .white
            label.textAlignment = .center
            hudView.contentView.addSubview(label)
        }

        mainContainer.addSubview(hudView)
        window.addSubview(mainContainer)
        containerView = mainContainer

        // 5. Entrance Animation (Pop effect only for HUD)
        hudView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        hudView.alpha = 0

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            hudView.alpha = 1
            hudView.transform = .identity
        }
    }

    func stopLoader() {
        guard let container = containerView else { return }

        // Exit Animation
        UIView.animate(withDuration: 0.2, animations: {
            container.alpha = 0
        }) { _ in
            container.removeFromSuperview()
            self.containerView = nil
        }
    }
}
