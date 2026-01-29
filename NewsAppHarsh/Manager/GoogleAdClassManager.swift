//
//  AdManager.swift
//
//  Created by Harsh on 27/01/26.
//
import GoogleMobileAds
import UIKit
import Network

// MARK: - Helper Struct for Native Ad Freshness 🧠
struct CachedNativeAd {
    let ad: NativeAd
    let loadTime: Date
    
    var isExpired: Bool {
        // Ads expire after 1 hour (3600 seconds)
        return Date().timeIntervalSince(loadTime) > 3600
    }
}

/// **GoogleAdClassManager**
/// Final Optimized Version: Includes Frequency Control, Expiration Checks, Thread Safety, and Adaptive Sizing.
final class GoogleAdClassManager: NSObject, FullScreenContentDelegate, NativeAdLoaderDelegate {
    
    static let shared = GoogleAdClassManager()

    // MARK: - Ad Unit IDs
    private let bannerTestID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialTestID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedTestID = "ca-app-pub-3940256099942544/1712485313"
    private let nativeTestID = "ca-app-pub-3940256099942544/3986624511"
    private let appOpenTestID = "ca-app-pub-3940256099942544/5575463023"

    // MARK: - Ad Objects
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var appOpenAd: AppOpenAd?
    
    // MARK: - Logic Variables
    private var appOpenLoadTime: Date?
    private var rewardedLoadTime: Date? // 🔥 Issue #3 Fix
    
    private var isShowingAd = false
    private var onInterstitialDismiss: (() -> Void)?
    
    // 🔥  Frequency Control
    private var lastFullScreenAdTime: Date?
    private let minimumAdInterval: TimeInterval = 10.0 // 10 Seconds gap
    
    // 🔥 Thread Safety (Serial Queue for Ads)
    // Using Main Thread for all ad logic is safest as Google Ads SDK must run on Main.
    
    // Internet Monitor
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = true

    // MARK: - Native Ads Properties
    private var adLoader: AdLoader?
    
    // 🔥 Issue #4: Store with Timestamp
    private var nativeAdPool: [CachedNativeAd] = []
    private var onNativeBatchLoaded: (() -> Void)?
    private let maxPoolSize = 5

    // MARK: - Initialisation
    override private init() {
        super.init()
        
        setupNetworkMonitoring()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["2cc011528157440b6b8672f41247f5f6"]
        MobileAds.shared.start(completionHandler: nil)

        // Load initially if connected
        if isConnected { loadAllAds() }
    }
    
    private func loadAllAds() {
        loadInterstitial()
        loadRewardedAd()
        loadAppOpenAd()
    }

    // MARK: - Network Monitor
    private func setupNetworkMonitoring() {
            self.isConnected = true
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                
                let isNowConnected = path.status == .satisfied
                
                // Only trigger reload if status changed from Offline -> Online
                if isNowConnected && !self.isConnected {
                    print("🟢🌐 Internet Back: Retrying All Ads")
                    
                    DispatchQueue.main.async {
                        // Retry loading missing ads
                        if self.interstitialAd == nil { self.loadInterstitial() }
                        if !self.isRewardedReady { self.loadRewardedAd() }
                        if self.appOpenAd == nil { self.loadAppOpenAd() }
                    }
                }
                self.isConnected = isNowConnected
            }
            monitor.start(queue: DispatchQueue.global(qos: .background))
        }

    @objc private func handleMemoryWarning() {
        nativeAdPool.removeAll() // Clear memory on warning
    }

    // MARK: - Frequency Cap Check (Issue #1)
    private func canShowFullScreenAd() -> Bool {
        guard let lastTime = lastFullScreenAdTime else { return true }
        let diff = Date().timeIntervalSince(lastTime)
        if diff < minimumAdInterval {
            print("⏳ canShowFullScreenAd : Ad Throttled: Only \(Int(diff))s passed since last ad.")
            return false
        }
        return true
    }
    
    private func recordAdImpression() {
        lastFullScreenAdTime = Date()
    }

    // MARK: - 1. Interstitial Ad
    func loadInterstitial() {
        guard isConnected else { return }
        let request = Request()
        InterstitialAd.load(with: interstitialTestID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let _ = error { return }
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func showInterstitial(from vc: UIViewController, onDismiss: @escaping () -> Void) {
        // Check Frequency
        guard canShowFullScreenAd() else {
            onDismiss()
            return
        }
        
        if let ad = interstitialAd {
            onInterstitialDismiss = onDismiss
            ad.present(from: vc)
        } else {
            onDismiss()
            loadInterstitial()
        }
    }

    // MARK: - 2. Rewarded Ad
    
    // 🔥 Improved Readiness Check (Expiration)
    var isRewardedReady: Bool {
        guard rewardedAd != nil, let loadTime = rewardedLoadTime else { return false }
        
        // Check if expired (1 hour limit)
        if Date().timeIntervalSince(loadTime) > 3600 {
            print("⚠️ isRewardedReady : Rewarded Ad Expired. Reloading.")
            rewardedAd = nil
            loadRewardedAd()
            return false
        }
        return true
    }

    func loadRewardedAd() {
        guard isConnected else { return }
        let request = Request()
        RewardedAd.load(with: rewardedTestID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let _ = error { return }
            self.rewardedAd = ad
            self.rewardedLoadTime = Date() // Store Time
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showRewardedAd(from vc: UIViewController, onReward: @escaping () -> Void, onAdNotReady: (() -> Void)? = nil) {
        guard canShowFullScreenAd() else { // Frequency Check
            onAdNotReady?()
            return
        }
        
        if isRewardedReady { // Uses new check
            onInterstitialDismiss = nil
            rewardedAd?.present(from: vc) {
                onReward()
            }
        } else {
            loadRewardedAd()
            onAdNotReady?()
        }
    }

    // MARK: - 3. Native Ad Logic

    func fetchNativeAdsBatch(rootVC: UIViewController, count: Int, completion: (() -> Void)? = nil) {
        guard isConnected else { completion?(); return }

        // Clean up expired ads first
        nativeAdPool = nativeAdPool.filter { !$0.isExpired }

        if nativeAdPool.count >= maxPoolSize {
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

    func getNextNativeAd() -> NativeAd? {
        // 🔥 Always access array on Main Thread logic (called from UI)
        // Also Filter expired ads on the fly
        if let firstValidIndex = nativeAdPool.firstIndex(where: { !$0.isExpired }) {
            let cachedAd = nativeAdPool.remove(at: firstValidIndex) // Remove to avoid reuse spam
            return cachedAd.ad
        }
        return nil
    }

    // MARK: - NativeAdLoaderDelegate
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        // 🔥 Ensure Main Thread
        DispatchQueue.main.async { [weak self] in
            // Add with Timestamp
            self?.nativeAdPool.append(CachedNativeAd(ad: nativeAd, loadTime: Date()))
        }
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        DispatchQueue.main.async { [weak self] in
            self?.onNativeBatchLoaded?()
            self?.onNativeBatchLoaded = nil
            self?.adLoader = nil
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.onNativeBatchLoaded?()
            self?.onNativeBatchLoaded = nil
            self?.adLoader = nil
        }
    }

    // MARK: - 4. App Open Ad

    func loadAppOpenAd() {
        guard isConnected else { return }
        if appOpenAd != nil || isShowingAd { return }
        
        AppOpenAd.load(with: appOpenTestID, request: Request()) { [weak self] ad, error in
            self?.appOpenAd = ad
            self?.appOpenLoadTime = Date()
            self?.appOpenAd?.fullScreenContentDelegate = self
        }
    }

    func showAppOpenAdIfAvailable(scene: UIWindowScene) {
        if isShowingAd { return }
        
        // Expiration Check (4 Hours)
        if let ad = appOpenAd, let time = appOpenLoadTime, Date().timeIntervalSince(time) < 14400 {
            
            // 🔥 Frequency Check: Don't show if user just saw an interstitial
            if !canShowFullScreenAd() { return }
            
            if let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                isShowingAd = true
                ad.present(from: rootVC)
            }
        } else {
            loadAppOpenAd()
        }
    }

    // MARK: - FullScreen Delegate (Handles Frequency Timer)
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingAd = false
        recordAdImpression() // 🔥 Start the 10s timer NOW
        
        if ad is AppOpenAd {
            appOpenAd = nil
            loadAppOpenAd()
        } else {
            onInterstitialDismiss?()
            onInterstitialDismiss = nil
            loadInterstitial()
            loadRewardedAd()
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isShowingAd = false
        if ad is AppOpenAd {
             appOpenAd = nil
             loadAppOpenAd()
        } else {
            onInterstitialDismiss?() // Don't block user if ad fails
        }
    }

    // MARK: - 5. Banner Ad (Issue #6 Fix)
    
    /// Helper to get width based on safe area
    private func getAdSize(for container: UIView) -> AdSize {
        let frame = container.frame.inset(by: container.safeAreaInsets)
        let viewWidth = frame.size.width
        return currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
    }

    func loadBanner(in bannerView: BannerView, rootVC: UIViewController) {
        guard isConnected else { return }
        bannerView.adUnitID = bannerTestID
        bannerView.rootViewController = rootVC
        bannerView.adSize = getAdSize(for: rootVC.view) // Initial Load
        bannerView.load(Request())
    }
    // Programmatically create a Banner View (For Container Views)
    func getProgrammaticBanner(rootVC: UIViewController) -> BannerView {
         
        let adaptiveSize = getAdSize(for: rootVC.view)
        let bannerView = BannerView(adSize: adaptiveSize)
        bannerView.adUnitID = bannerTestID
        bannerView.rootViewController = rootVC
        if isConnected {
            bannerView.load(Request())
        } else {
            print("⚠️ No Internet: ProgrammaticBanner Banner created but request skipped.")
        }
        return bannerView
    }
    
    /// Call this from `viewWillTransition` in ViewController
    func updateBannerSize(for bannerView: BannerView, size: CGSize) {
        // Just updating the size isn't enough, we often need to reload or just resize depending on policy.
        // For adaptive banners, GADCurrentOrientation... handles the request,
        // but on rotation, we should invalidate and fetch a new size.
        
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(
            width: size.width
        )
    }
}
