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
        
        // 1. Main Container (Transparent)
        let mainContainer = UIView(frame: window.bounds)
        mainContainer.backgroundColor = .clear
        mainContainer.isUserInteractionEnabled = true
        
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
        
        // Move indicator up slightly to make room for 2 lines of text
        let yOffset: CGFloat = (message == nil) ? 0 : 15
        indicator.center = CGPoint(x: hudView.bounds.midX, y: hudView.bounds.midY - yOffset)
        indicator.startAnimating()
        
        hudView.contentView.addSubview(indicator)
        
        // 4. Message Label (Updated for 2 Lines & Auto Scale) 🚀
        if let text = message, !text.isEmpty {
            // Increased height (34) and moved Y up (62) to fit 2 lines
            let label = UILabel(frame: CGRect(x: 4, y: 62, width: 92, height: 34))
            
            label.text = text
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .white
            label.textAlignment = .center
            
            // ✅ Allow 2 Lines
            label.numberOfLines = 2
            
            // ✅ Auto Shrink Font if text is long
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7 // Scale down to 70% if needed
            
            hudView.contentView.addSubview(label)
        }
        
        mainContainer.addSubview(hudView)
        window.addSubview(mainContainer)
        containerView = mainContainer
        
        // 5. Entrance Animation
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
