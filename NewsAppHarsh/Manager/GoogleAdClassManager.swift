//
//  AdManager.swift
//
//  Created by Harsh on 27/01/26.
//
import GoogleMobileAds
import UIKit
/// **GoogleAdClassManager**
/// A Singleton class responsible for handling all AdMob ads (Banner, Interstitial, Rewarded, Native, App Open).
/// Updated with Native Ad Pooling for smooth pagination.
final class GoogleAdClassManager: NSObject, FullScreenContentDelegate, NativeAdLoaderDelegate {
    
    // MARK: - Singleton Access
    static let shared = GoogleAdClassManager()

    // MARK: - Ad Unit IDs
    // ⚠️ Replace with Real IDs before Release
    private let bannerTestID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialTestID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedTestID = "ca-app-pub-3940256099942544/1712485313"
    private let nativeTestID = "ca-app-pub-3940256099942544/3986624511"
    private let appOpenTestID = "ca-app-pub-3940256099942544/5575463023"

    // MARK: - Properties (General)
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var appOpenAd: AppOpenAd?
    
    // App Open Ad Logic
    private var loadTime: Date?
    private var isShowingAd = false
    private var onInterstitialDismiss: (() -> Void)?

    // MARK: - Properties (Native Ads 🧠)
    
    private var adLoader: AdLoader?
    
    /// **The Pool:** Stores all downloaded native ads in memory.
    private var nativeAdPool: [NativeAd] = []
    
    /// **Circular Index:** Tracks which ad to show next.
    private var currentAdIndex = 0
    
    /// Callback when a batch of ads finishes loading.
    private var onNativeBatchLoaded: (() -> Void)?

    // MARK: - Initialization
    override private init() {
        super.init()
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["2cc011528157440b6b8672f41247f5f6"]
         
        MobileAds.shared.start(completionHandler: nil)

        // Pre-load ads immediately
        loadInterstitial()
        loadRewardedAd()
        loadAppOpenAd()
    }

    // MARK: - 1. Interstitial Ad Logic (Full Screen)

    func loadInterstitial() {
        let request = Request()
        InterstitialAd.load(with: interstitialTestID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ Interstitial Failed: \(error.localizedDescription)")
                return
            }
            print("✅ Interstitial Ad Loaded")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func showInterstitial(from vc: UIViewController, onDismiss: @escaping () -> Void) {
        if let ad = interstitialAd {
            onInterstitialDismiss = onDismiss
            ad.present(from: vc)
        } else {
            print("⚠️ Interstitial Not Ready")
            onDismiss()
            loadInterstitial()
        }
    }

    // MARK: - 2. Rewarded Ad Logic (Video Reward)

    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: rewardedTestID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ Rewarded Failed: \(error.localizedDescription)")
                return
            }
            print("✅ Rewarded Ad Loaded")
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showRewardedAd(from vc: UIViewController, onReward: @escaping () -> Void, onAdNotReady: (() -> Void)? = nil) {
        if let ad = rewardedAd {
            onInterstitialDismiss = nil // Clear navigation logic for safety
            ad.present(from: vc) {
                print("🎁 User earned reward!")
                onReward()
            }
        } else {
            print("⚠️ Rewarded Ad Not Ready")
            loadRewardedAd()
            onAdNotReady?()
        }
    }

    // MARK: - 3. Native Ad Logic (Optimized for Feed 🚀)

    /// Loads a batch of Native Ads and adds them to the Pool.
    /// - Parameters:
    ///   - count: Number of ads to fetch (e.g., 3).
    ///   - completion: Called when the batch is processed (Success or Fail).
    func fetchNativeAdsBatch(rootVC: UIViewController, count: Int, completion: (() -> Void)? = nil) {
        
        // 1. Memory Safety Check
        // If we already have enough ads (e.g. 15), don't fetch more. Reuse existing ones.
        if nativeAdPool.count >= FeedConfig.maxAdPoolSize {
            print("🛑 Ad Pool Full (\(nativeAdPool.count)). Reusing existing ads.")
            completion?()
            return
        }

        self.onNativeBatchLoaded = completion
        
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = count

        adLoader = AdLoader(adUnitID: nativeTestID,
                            rootViewController: rootVC,
                            adTypes: [.native],
                            options: [multipleAdsOptions])
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    /// **Circular Logic:** Returns the next ad from the pool.
    /// If we reach the end, it loops back to the start.
    func getNextNativeAd() -> NativeAd? {
        guard !nativeAdPool.isEmpty else { return nil }
        
        // Get current ad
        let ad = nativeAdPool[currentAdIndex]
        
        // Move to next index (Loop back to 0 if at end)
        currentAdIndex = (currentAdIndex + 1) % nativeAdPool.count
        
        return ad
    }
    
    // MARK: - NativeAdLoaderDelegate

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("✅ Native Ad Received")
        nativeAdPool.append(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        print("ℹ️ Native Batch Finished. Total Ads in Pool: \(nativeAdPool.count)")
        onNativeBatchLoaded?()
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ Native Batch Failed: \(error.localizedDescription)")
        // Call completion anyway so the app flow doesn't stop
        onNativeBatchLoaded?()
    }

    // MARK: - 4. App Open Ad Logic (Launch Ad)

    func loadAppOpenAd() {
        if isAppOpenAdAvailable() || isShowingAd { return }
        let request = Request()
        AppOpenAd.load(with: appOpenTestID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ App Open Ad Failed: \(error.localizedDescription)")
                return
            }
            print("✅ App Open Ad Loaded")
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
        }
    }

    private func isAppOpenAdAvailable() -> Bool {
        guard let ad = appOpenAd, let loadTime = loadTime else { return false }
        // Expire after 4 hours
        return Date().timeIntervalSince(loadTime) < 14400
    }

    func showAppOpenAdIfAvailable(scene: UIWindowScene) {
        if isShowingAd { return }
        if !isAppOpenAdAvailable() {
            loadAppOpenAd()
            return
        }
        guard let window = scene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else { return }
        
        isShowingAd = true
        appOpenAd?.present(from: rootVC)
    }

    // MARK: - FullScreenContentDelegate (Global)

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if ad is AppOpenAd {
            print("ℹ️ App Open Ad Dismissed")
            appOpenAd = nil
            isShowingAd = false
            loadAppOpenAd()
            return
        }
        
        print("ℹ️ Ad Dismissed")
        onInterstitialDismiss?()
        onInterstitialDismiss = nil
        
        loadInterstitial()
        loadRewardedAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Presentation Failed: \(error.localizedDescription)")
        if ad is AppOpenAd {
            appOpenAd = nil
            isShowingAd = false
            loadAppOpenAd()
            return
        }
        onInterstitialDismiss?()
        onInterstitialDismiss = nil
        loadInterstitial()
        loadRewardedAd()
    }

    // MARK: - 5. Banner Ad Logic

    func loadBanner(in bannerView: BannerView, rootVC: UIViewController) {
        bannerView.adUnitID = bannerTestID
        bannerView.rootViewController = rootVC
        bannerView.adSize = AdSizeBanner
        bannerView.load(Request())
    }

    func getProgrammaticBanner(rootVC: UIViewController) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = bannerTestID
        bannerView.rootViewController = rootVC
        bannerView.load(Request())
        return bannerView
    }

    // MARK: - Helpers
    
    func isRewardedAdReady() -> Bool {
        return rewardedAd != nil
    }
}
