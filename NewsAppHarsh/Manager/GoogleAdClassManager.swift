//
//  AdManager.swift
//
//  Created by Harsh on 27/01/26.
//

import GoogleMobileAds
import UIKit

// MARK: - Feed Configuration

struct FeedConfig {
    static let adInterval = 5 // Show Ad after every 5 news items
    static let maxAdPoolSize = 15 // RAM saver limit (max ad gather limit - circular logic)
    static let adBatchSize = 3 // Batch fetch size(fetch ad at a time from server)
}

// MARK: - Feed Mode

enum FeedMode {
    case online
    case offline
}

// MARK: - Wrapper for Native Ad Expiry

struct CachedNativeAd {
    let ad: NativeAd
    let loadTime: Date

    var isExpired: Bool {
        // Expire after 1 hour (3600s)
        return Date().timeIntervalSince(loadTime) > 3600
    }
}

/// **GoogleAdClassManager**
/// Centralized manager for all AdMob logic (Banner, Interstitial, Rewarded, Native, App Open).
final class GoogleAdClassManager: NSObject, FullScreenContentDelegate, NativeAdLoaderDelegate {
    static let shared = GoogleAdClassManager()

    // MARK: - Ad Unit IDs

    // ⚠️ Replace with Real IDs before Release
    private let bannerTestID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialTestID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedTestID = "ca-app-pub-3940256099942544/1712485313"
    private let nativeTestID = "ca-app-pub-3940256099942544/3986624511"
    private let appOpenTestID = "ca-app-pub-3940256099942544/5575463023"

    // MARK: - Ad Properties

    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var appOpenAd: AppOpenAd?

    // Timestamps
    private var appOpenLoadTime: Date?
    private var rewardedLoadTime: Date?

    // State Flags
    private var isShowingAd = false
    private var onFullScreenAdDismiss: (() -> Void)?

    // Loading Flags (To prevent double calls)
    private var isLoadingInterstitial = false
    private var isLoadingRewarded = false
    private var isLoadingAppOpenAd = false

    // Frequency Control
    private var lastFullScreenAdTime: Date?
    private let minimumAdInterval: TimeInterval = 10.0

    // Native Ad Pool
    private var adLoader: AdLoader?
    private var nativeAdPool: [CachedNativeAd] = []
    private var currentAdIndex = 0
    private var onNativeBatchLoaded: (() -> Void)?

    // MARK: - Initialisation

    override private init() {
        super.init()

        // 1. Network Listener
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            guard let self = self else { return }
            print(isConnected ? "🌐 Network: Online" : "⛔ Network: Offline")

            if isConnected {
                print("♻️ Retrying failed ads...Ad Loading call FROM NetworkMonitor")

                // This checks if ads are missing AND not currently loading
                if self.interstitialAd == nil { self.loadInterstitial() }
                if !self.isRewardedReady { self.loadRewardedAd() }
                if self.appOpenAd == nil { self.loadAppOpenAd() }
            }
        }

        // 2. Memory Warning Listener
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // 3. Initialize SDK
        MobileAds.shared.start(completionHandler: nil)

        // 4. Initial Load
        if NetworkMonitor.shared.isConnected {
            print("🚀 Init: Preloading Ads...Ad Loading call FROM INIT")
            loadAllAds()
        }
    }

    private func loadAllAds() {
        loadInterstitial()
        loadRewardedAd()
        loadAppOpenAd()
    }

    @objc private func handleMemoryWarning() {
        print("⚠️ Memory Warning: Clearing Native Ad Pool.")
        nativeAdPool.removeAll()
        currentAdIndex = 0
    }

    // MARK: - Frequency Logic

    private func canShowFullScreenAd() -> Bool {
        guard let lastTime = lastFullScreenAdTime else { return true }
        let diff = Date().timeIntervalSince(lastTime)

        if diff < minimumAdInterval {
            print("⏳ Ad Throttled: \(Int(diff))s since last ad.Can't show ad because there is time limit between two ads 10s")
            return false
        }
        return true
    }

    private func recordAdImpression() {
        lastFullScreenAdTime = Date()
    }

    // MARK: - 1. Interstitial Ad

    func loadInterstitial() {
        guard NetworkMonitor.shared.isConnected else { return }

        // Prevent Double Call: If already loading, STOP here.
        if isLoadingInterstitial {
            print("⚠️ Interstitial: Already loading... request ignored")
            return
        }

        print("🟡 Interstitial: Ad Requested")
        isLoadingInterstitial = true // 🚩 Lock

        InterstitialAd.load(with: interstitialTestID, request: Request()) { [weak self] ad, error in

            self?.isLoadingInterstitial = false // 🔓 Unlock

            if let error = error {
                print("❌ Interstitial Failed: \(error.localizedDescription)")
                return
            }
            print("✅ Interstitial: Loaded")
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func showInterstitial(from vc: UIViewController, onDismiss: @escaping () -> Void) {
        guard canShowFullScreenAd() else {
            onDismiss()
            return
        }

        guard let ad = interstitialAd else {
            print("⚠️ Interstitial Not Ready: Reloading...")
            onDismiss()
            loadInterstitial()
            return
        }

        print("⭐️ Showing Interstitial")
        onFullScreenAdDismiss = onDismiss
        ad.present(from: vc)
    }

    // MARK: - 2. Rewarded Ad

    var isRewardedReady: Bool {
        guard let loadTime = rewardedLoadTime, rewardedAd != nil else { return false }

        if Date().timeIntervalSince(loadTime) > 3600 {
            print("⏰ Rewarded Expired: discarding.")
            rewardedAd = nil
            loadRewardedAd()
            return false
        }
        return true
    }

    func loadRewardedAd() {
        guard NetworkMonitor.shared.isConnected else { return }

        // Prevent Double Call
        if isLoadingRewarded {
            print("⚠️ Rewarded: Already loading... request ignored")
            return
        }

        print("🟡 Rewarded: Ad Requested")
        isLoadingRewarded = true // 🚩 Lock

        RewardedAd.load(with: rewardedTestID, request: Request()) { [weak self] ad, error in

            self?.isLoadingRewarded = false // 🔓 Unlock

            if let error = error {
                print("❌ Rewarded Failed: \(error.localizedDescription)")
                return
            }
            print("✅ Rewarded: Loaded")
            self?.rewardedAd = ad
            self?.rewardedLoadTime = Date()
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showRewardedAd(from vc: UIViewController, onReward: @escaping () -> Void, onAdNotReady: (() -> Void)? = nil) {
        if self.interstitialAd == nil { self.loadInterstitial() }
        // Check Frequency (10s Cooldown)
        // Note: canShowFullScreenAd() prints its own error if it fails.
        if !canShowFullScreenAd() {
            onAdNotReady?()
            return
        }

        // Check if Ad is actually ready
        if !isRewardedReady {
            print("⚠️ RewardedAd Failed: Ad is not ready (Expired or Nil).")
            onAdNotReady?()
            return
        }

        // ✅ Success
        print("⭐️ Showing Rewarded Ad")
        rewardedAd?.present(from: vc) {
            print("🎁 Reward Earned")
            onReward()
        }
    }

    // MARK: - 3. Native Ads (Circular Logic)

    func fetchNativeAdsBatch(rootVC: UIViewController, count: Int, completion: (() -> Void)? = nil) {
        guard NetworkMonitor.shared.isConnected else {
            completion?()
            return
        }

        // Clean expired ads
        nativeAdPool = nativeAdPool.filter { !$0.isExpired }

        // Stop if pool is full
        if nativeAdPool.count >= FeedConfig.maxAdPoolSize {
            print("🛑 NativeAd Pool Full (\(nativeAdPool.count)). Skipping new Ad fetch from server.")
            completion?()
            return
        }

        print("🟡 NativeAd Batch: Requesting \(count) ads...")
        onNativeBatchLoaded = completion

        let options = MultipleAdsAdLoaderOptions()
        options.numberOfAds = count

        adLoader = AdLoader(
            adUnitID: nativeTestID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: [options]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    func getNextNativeAd() -> NativeAd? {
        guard !nativeAdPool.isEmpty else { return nil }

        // Circular Logic: Get current -> Increment Index -> Loop
        let cachedAd = nativeAdPool[currentAdIndex]
        currentAdIndex = (currentAdIndex + 1) % nativeAdPool.count

        return cachedAd.ad
    }

    // MARK: Native Delegate

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAdPool.append(CachedNativeAd(ad: nativeAd, loadTime: Date()))
        }
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        DispatchQueue.main.async {
            print("✅ NativeAd Current Batch Finished. Pool Size: \(self.nativeAdPool.count)")
            self.onNativeBatchLoaded?()
            self.onNativeBatchLoaded = nil
            self.adLoader = nil
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ NativeAd Batch Failed: \(error.localizedDescription)")
        adLoaderDidFinishLoading(adLoader)
    }

    // MARK: - 4. App Open Ads

    func loadAppOpenAd() {
        // Check Network
        guard NetworkMonitor.shared.isConnected else {
            print("⛔ AppOpenAd Load Skipped: No Internet")
            return
        }

        // Check if already loading (Double Call Protection)
        if isLoadingAppOpenAd {
            print("⚠️ AppOpenAd: Already loading... request ignored")
            return
        }

        // Check if Ad is already loaded
        if appOpenAd != nil {
            print("⚠️ AppOpenAd: Ad already exists in memory. Skipping load.")
            return
        }

        // Check if currently showing
        if isShowingAd {
            print("⚠️ AppOpenAd: Ad is currently showing. Skipping load.")
            return
        }

        print("🟡 AppOpenAd : Load Requested")
        isLoadingAppOpenAd = true // 🚩 Lock

        AppOpenAd.load(with: appOpenTestID, request: Request()) { [weak self] ad, error in

            self?.isLoadingAppOpenAd = false // 🔓 Unlock

            if let error = error {
                print("❌ App Open Failed: \(error.localizedDescription)")
                return
            }
            print("✅ AppOpenAd : Loaded")
            self?.appOpenAd = ad
            self?.appOpenLoadTime = Date()
            self?.appOpenAd?.fullScreenContentDelegate = self
        }
    }

    func showAppOpenAdIfAvailable(scene: UIWindowScene) {
        print("🚪 AppOpenAd : Request to show...")

        // Check if another ad is showing
        if isShowingAd {
            print("⛔ AppOpenAd Failed: Another ad is already showing")
            return
        }

        // Check if Ad is loaded
        guard let ad = appOpenAd, let time = appOpenLoadTime else {
            print("⛔ AppOpenAd Failed: Ad is nil, triggering reload...")
            loadAppOpenAd()
            return
        }

        // Check Ad Expiry (4 Hours)
        if Date().timeIntervalSince(time) > 14400 {
            print("⛔ AppOpenAd Failed: Ad expired, clearing and reloading...")
            appOpenAd = nil
            loadAppOpenAd()
            return
        }

        // Check Frequency Cap (10s cooldown)
        if !canShowFullScreenAd() {
            print("⛔ AppOpenAd Failed: Throttled by 10s cooldown logic")
            return
        }

        // Get Root View Controller
        guard let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("⛔ AppOpenAd Failed: Root VC not found")
            return
        }

        // ✅ All checks passed
        print("⭐️ Showing AppOpenAd")
        isShowingAd = true
        ad.present(from: rootVC)
    }

    // MARK: - FullScreen Delegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("❌ Ad Dismissed")
        isShowingAd = false
        recordAdImpression()
        onFullScreenAdDismiss?()
        onFullScreenAdDismiss = nil
        
        if ad is AppOpenAd {
            print("♻️ AppOpenAd Closed: Reloading...")
            appOpenAd = nil
            loadAppOpenAd()
        }
        else if ad is InterstitialAd {
            print("♻️ Interstitial Closed: Reloading...")
            interstitialAd = nil
            loadInterstitial()
        }
        else if ad is RewardedAd {
            print("♻️ Rewarded Closed: Reloading...")
            rewardedAd = nil
            loadRewardedAd()
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad Presentation Failed: \(error.localizedDescription)")
        isShowingAd = false
        onFullScreenAdDismiss?()
        onFullScreenAdDismiss = nil
    }

    // MARK: - 5. Banner Ads

    // 🔥 Helper for Adaptive Size (Avoids duplication)
    private func getAdSize(for container: UIView) -> AdSize {
        let width = container.frame.inset(by: container.safeAreaInsets).width
        return currentOrientationAnchoredAdaptiveBanner(width: width)
    }

    func loadBanner(in bannerView: BannerView, rootVC: UIViewController) {
        guard NetworkMonitor.shared.isConnected else { return }

        bannerView.adUnitID = bannerTestID
        bannerView.rootViewController = rootVC
        bannerView.adSize = getAdSize(for: rootVC.view)
        bannerView.load(Request())
    }

    func getProgrammaticBanner(rootVC: UIViewController) -> BannerView {
        let banner = BannerView(adSize: getAdSize(for: rootVC.view))
        banner.adUnitID = bannerTestID
        banner.rootViewController = rootVC

        if NetworkMonitor.shared.isConnected {
            banner.load(Request())
        }
        return banner
    }

    func updateBannerSize(for bannerView: BannerView, size: CGSize) {
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(
            width: size.width
        )
    }
}
