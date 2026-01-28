//
//  SceneDelegate.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import AdSupport
import AppTrackingTransparency // Required for ATT Prompt
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Step 1: Wait 1 second (User settles down)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Step 2: Request Permission FIRST
            self.requestTrackingPermission {
                // Step 3: ONLY after permission logic is done, try to show the Ad
                print("🔄 Permission flow finished. Now trying to show App Open Ad.")
                GoogleAdClassManager.shared.showAppOpenAdIfAvailable(scene: windowScene)
            }
        }
    }
    // MARK: - App Tracking Transparency (ATT) Logic

    /// Requests ATT permission and runs the `completion` block when done.
    func requestTrackingPermission(completion: @escaping () -> Void) {
        if #available(iOS 14, *) {
            // Check current status
            let currentStatus = ATTrackingManager.trackingAuthorizationStatus

            switch currentStatus {
            case .notDetermined:
                // If asking for the first time, show the Alert
                ATTrackingManager.requestTrackingAuthorization { _ in
                    // This block runs on a background thread, so bring it to Main Thread
                    DispatchQueue.main.async {
                        print("👤 User made a choice about tracking.")
                        completion() // Run the next step (Show Ad)
                    }
                }
            case .authorized, .denied, .restricted:
                // If already asked before, don't wait. Just proceed.
                print("ℹ️ Permission already handled previously.")
                completion()

            @unknown default:
                completion()
            }
        } else {
            // Fallback for older iOS versions
            completion()
        }
    }


    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
    }
}
