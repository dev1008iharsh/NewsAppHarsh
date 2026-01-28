//
//  NewsListHomeVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import GoogleMobileAds
import UIKit

final class NewsHomeVC: UIViewController {
    // MARK: - Outlets

    @IBOutlet private var tblNewsList: UITableView!
    @IBOutlet var bannerContainerView: UIView!

    // MARK: - Properties

    private let viewModel = NewsViewModel()
    private let refreshControl = UIRefreshControl()

    // Pagination & State
    private var totalResultsCount = 0
    private var totalPage = 1
    private var currentPage = 1
    private var isLoading = false // Controls API + Ad fetching state
    private var currentFeedMode: FeedMode = .online

    // Track selected URL for rewarded ad flow
    private var selectedArticleUrl: String?

    // Network Tracking
    private var lastConnectionStatus: Bool?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNetworkObserver()
        setupBannerInContainer()
        loadFreshData()
    }

    // MARK: - Setup UI

    private func setupUI() {
        title = "Breaking News"

        // Register Cells
        tblNewsList.register(UINib(nibName: "NewsTVC", bundle: nil), forCellReuseIdentifier: "NewsTVC")
        tblNewsList.register(UINib(nibName: "NativeAdTVC", bundle: nil), forCellReuseIdentifier: "NativeAdTVC")

        // TableView Configuration
        tblNewsList.refreshControl = refreshControl
        tblNewsList.dataSource = self
        tblNewsList.delegate = self
        tblNewsList.estimatedRowHeight = 250
        tblNewsList.rowHeight = UITableView.automaticDimension

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    private func setupBannerInContainer() {
        let bannerView = GoogleAdClassManager.shared.getProgrammaticBanner(rootVC: self)
        bannerView.backgroundColor = .clear

        bannerContainerView.addSubview(bannerView)
        bannerContainerView.layer.cornerRadius = 8
        bannerContainerView.clipsToBounds = true

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: bannerContainerView.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: bannerContainerView.bottomAnchor),
            bannerView.leadingAnchor.constraint(equalTo: bannerContainerView.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: bannerContainerView.trailingAnchor),
        ])
    }

    // MARK: - Network Observer

    private func setupNetworkObserver() {
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            guard let self = self else { return }

            if self.lastConnectionStatus == isConnected { return }
            let previousStatus = self.lastConnectionStatus
            self.lastConnectionStatus = isConnected
            self.currentFeedMode = isConnected ? .online : .offline

            if previousStatus == nil {
                if !isConnected { self.showOfflineToast() }
            } else {
                isConnected ? self.showBackOnlineAlert() : self.showOfflineToast()
            }
        }
    }

    private func showBackOnlineAlert() {
        if presentedViewController is UIAlertController { return }

        let alert = UIAlertController(title: "Back Online 🟢", message: "You are connected to network now. Do you want to fetch latest news?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        alert.addAction(UIAlertAction(title: "Fetch", style: .default) { [weak self] _ in
            self?.refreshData()
        })
        
        present(alert, animated: true)
    }

    private func showOfflineToast() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            LoaderManager.shared.stopLoader()
            self.refreshControl.endRefreshing()
            self.isLoading = false // Reset loading state on error
            HapticManager.shared.play(.warning)

            let toast = UILabel(frame: CGRect(x: 40, y: self.view.frame.height - 100, width: self.view.frame.width - 80, height: 60))
            toast.backgroundColor = .systemRed
            toast.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            toast.text = "Offline Mode"
            toast.textColor = .white
            toast.textAlignment = .center
            toast.layer.cornerRadius = 20
            toast.clipsToBounds = true
            toast.alpha = 0
            self.view.addSubview(toast)

            UIView.animate(withDuration: 0.5, animations: { toast.alpha = 1 }) { _ in
                UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: { toast.alpha = 0 }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }

    // MARK: - Data Loading Logic

    private func loadFreshData() {
        // Prevent duplicate calls if already loading
        if isLoading { return }

        if NetworkMonitor.shared.isConnected {
            isLoading = true // Lock immediately
            currentFeedMode = .online
            bannerContainerView.isHidden = false

            // Fetch Ads first to ensure correct insertion into the list
            // If ad loads or failed the completion code will always run
            GoogleAdClassManager.shared.fetchNativeAdsBatch(rootVC: self, count: FeedConfig.adBatchSize) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    // Fetch News after ads are handled
                    self.viewModel.fetchNewsApi(page: self.currentPage)
                }
            }
        } else {
            fetchOfflineData()
            bannerContainerView.isHidden = true
            currentFeedMode = .offline
            if viewModel.articles.isEmpty { showOfflineToast() }
        }
    }

    private func fetchOfflineData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentFeedMode = .offline
            self.viewModel.articles = DBManager.shared.fetchCoreDataNews()
            self.viewModel.refreshFeed(mode: .offline)
            self.tblNewsList.reloadData()
        }
    }

    @objc private func refreshData() {
        if isLoading {
            refreshControl.endRefreshing()
            return
        }
        currentPage = 1
        HapticManager.shared.play(.light)
        loadFreshData()
    }

    // MARK: - ViewModel Bindings

    private func setupBindings() {
        viewModel.eventHandler = { [weak self] event in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleViewModelEvent(event)
            }
        }
    }

    private func handleViewModelEvent(_ event: NewsViewModel.Event) {
        switch event {
        case .loading:
            // isLoading is already set to true in loadFreshData/willDisplay
            // Just handle UI here
            if viewModel.articles.isEmpty {
                LoaderManager.shared.startLoader(message: "Fetching latest news...")
            }
            /* NO needed here because we are showing loader in willDisplayCell... it was not showing immediately because we are loading ad first after that loading api data

            else if currentPage > 1 {
                tblNewsList.showBottomLoader()
            }*/

        case .stopLoading:
            isLoading = false // ✅ Unlock logic
            LoaderManager.shared.stopLoader()
            tblNewsList.hideBottomLoader()
            refreshControl.endRefreshing()

        case .dataLoaded:
            // isLoading remains true until DB save completes or handled here
            handleDataLoaded()

        case let .network(error):
            isLoading = false // ✅ Unlock on error
            print("Network Error: \(error?.localizedDescription ?? "Unknown")")
            showAlert(title: "Error", message: error?.localizedDescription ?? "Something went wrong")
        }
    }

    private func handleDataLoaded() {
        totalResultsCount = viewModel.newsDataModel?.totalResults ?? 0
        totalPage = Int(ceil(Double(totalResultsCount) / 20.0))

        // Skip DB save if Page 1 data is identical
        if currentPage == 1 {
            let savedArticles = DBManager.shared.fetchCoreDataNews()
            if savedArticles == viewModel.articles {
                print("✅ Data synced already. Skipping DB Save.")
                isLoading = false // ✅ Unlock logic
                LoaderManager.shared.stopLoader()
                refreshControl.endRefreshing()
                tblNewsList.reloadData()
                return
            }

            DBManager.shared.deleteAllData { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async { self.saveAndRefresh() }
            }
        } else {
            saveAndRefresh()
        }
    }

    private func saveAndRefresh() {
        DBManager.shared.saveNewsCoreData(newData: viewModel.articles) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false // ✅ Final Unlock
                LoaderManager.shared.stopLoader()
                self.tblNewsList.reloadData()
                HapticManager.shared.play(.success)
            }
        }
    }

    // MARK: - Rewarded Ad Logic 🏆

    private func showRewardAdAlert() {
        let alert = UIAlertController(
            title: "Unlock Premium Article 🔓",
            message: "Watch a short video to read the complete article and detailed analysis. Your support helps us provide quality journalism!",
            preferredStyle: .alert
        )

        let watchAction = UIAlertAction(title: "Watch & Read 📰", style: .default) { [weak self] _ in
            self?.launchRewardedAd()
        }

        let cancelAction = UIAlertAction(title: "Maybe Later", style: .destructive, handler: nil)

        
        alert.addAction(cancelAction)
        alert.addAction(watchAction)

        present(alert, animated: true)
    }

    private func launchRewardedAd() {
        LoaderManager.shared.startLoader(message: "Loading Ad...")

        GoogleAdClassManager.shared.showRewardedAd(from: self, onReward: { [weak self] in
            guard let self = self else { return }
            LoaderManager.shared.stopLoader()
            print("🎉 Reward earned! Navigating...")
            self.openNewsArticle()
        }, onAdNotReady: { [weak self] in
            guard let self = self else { return }
            LoaderManager.shared.stopLoader()
            print("⚠️ Ad not ready. Fallback to content.")
            self.openNewsArticle()
        })
    }

    private func openNewsArticle() {
        guard let urlStr = selectedArticleUrl, !urlStr.isEmpty else { return }
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
        nextVC.strNewsUrl = urlStr
        HapticManager.shared.play(.light)
        navigationController?.pushViewController(nextVC, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate

extension NewsHomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.feedItems[indexPath.row]

        switch item {
        case let .news(article):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTVC", for: indexPath) as? NewsTVC else {
                return UITableViewCell()
            }
            cell.article = article

            // Read Button Action -> Triggers Reward Flow
            cell.onReadButtonTapped = { [weak self] in
                guard let self = self else { return }
                if NetworkMonitor.shared.isConnected {
                    self.selectedArticleUrl = article.articleUrl
                    self.showRewardAdAlert()
                } else {
                    HapticManager.shared.play(.error)
                    showOfflineToast()
                    showAlert(title: "Offline mode activated", message: "Internet connection required to read full article.")
                }
            }

            cell.onImageTapped = { [weak self] imgView in
                guard let self = self, let img = imgView.image else { return }
                let hdUrl = URL(string: article.imageUrl ?? "")
                let info = HpdImageInfo(image: img, imageMode: .aspectFit, imageHD: hdUrl)
                let trans = HpdTransitionInfo(fromView: imgView)
                let viewer = HpdImageViewerController(imageInfo: info, transitionInfo: trans)
                self.present(viewer, animated: true)
            }
            return cell

        case let .ad(nativeAd):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NativeAdTVC", for: indexPath) as? NativeAdTVC else {
                return UITableViewCell()
            }
            cell.configure(with: nativeAd)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case let .news(article) = viewModel.feedItems[indexPath.row] {
            // every 3rd time it will show ad
            Constant.detailScreenCounterAd += 1

            let navigateToDetails = { [weak self] in
                guard let self = self else { return }
                let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "NewsDetailsVC") as! NewsDetailsVC
                nextVC.article = article
                self.navigationController?.pushViewController(nextVC, animated: true)
            }

            if Constant.detailScreenCounterAd % 3 == 0 {
                GoogleAdClassManager.shared.showInterstitial(from: self) {
                    navigateToDetails()
                }
            } else {
                navigateToDetails()
            }
        }
    }

    // MARK: - Pagination Logic 🔄

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastRow = indexPath.row == viewModel.feedItems.count - 1

        if isLastRow, currentPage < totalPage, !isLoading {
            // Lock immediately to prevent duplicate calls
            isLoading = true
            currentPage += 1
            HapticManager.shared.play(.selection)

            // Check Feed Mode here
            if currentFeedMode == .online {
                // Online Mode: Fetch Ads -> Then Fetch Data
                tblNewsList.showBottomLoader()
                GoogleAdClassManager.shared.fetchNativeAdsBatch(rootVC: self, count: FeedConfig.adBatchSize) { [weak self] in
                    guard let self = self else { return }

                    // Fetch News API after ads logic completes
                    self.viewModel.fetchNewsApi(page: self.currentPage)
                }
            } else {
                print("⚠️ Offline Mode: Pagination skipped")
                isLoading = false
                currentPage -= 1 // Revert page increment as load failed
            }
        }
    }
}
