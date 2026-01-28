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

    // Pagination Properties
    private var totalResultsCount = 0
    private var totalPage = 1
    private var currentPage = 1

    // Flag to prevent duplicate API calls
    private var isLoading = false

    // Network Status Tracking
    private var lastConnectionStatus: Bool?
    private var currentFeedMode: FeedMode = .online
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupBindings()
        setupNetworkObserver() // 📡 Start listening to network changes
 
        setupBannerInContainer()
        
        fetchOfflineData()
 
        loadFreshData()
    }

    // MARK: - Setup UI

    private func setupBannerInContainer() {
        let bannerView = GoogleAdClassManager.shared.getProgrammaticBanner(rootVC: self)
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

    private func setupUI() {
        title = "Breaking News"

        // Register News Cell
        tblNewsList.register(UINib(nibName: "NewsTVC", bundle: nil), forCellReuseIdentifier: "NewsTVC")

        // Register Native Ad Cell (Make sure XIB exists)
        tblNewsList.register(UINib(nibName: "NativeAdTVC", bundle: nil), forCellReuseIdentifier: "NativeAdTVC")

        tblNewsList.refreshControl = refreshControl
        tblNewsList.dataSource = self
        tblNewsList.delegate = self

        // Smooth Scrolling Settings
        tblNewsList.estimatedRowHeight = 300
        tblNewsList.rowHeight = UITableView.automaticDimension

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    private func setupNavigationBar() {
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshNavBarButtonTapped)
        )
        navigationItem.rightBarButtonItem = refreshButton
    }

    @objc private func refreshNavBarButtonTapped() {
        print("Refresh button tapped! 🔄")
        HapticManager.shared.play(.warning)
        // Show Interstitial Ad -> Refresh Data
        GoogleAdClassManager.shared.showInterstitial(from: self) { [weak self] in
            guard let self else { return }

            if self.tblNewsList.numberOfRows(inSection: 0) > 0 {
                let topIndexPath = IndexPath(row: 0, section: 0)
                self.tblNewsList.scrollToRow(at: topIndexPath, at: .top, animated: true)
            }
            self.refreshData()
        }
    }

    // MARK: - Network Observer (Pro Logic 🚀)

    private func setupNetworkObserver() {
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            guard let self = self else { return }

            // Prevent duplicate updates
            if self.lastConnectionStatus == isConnected { return }

            let previousStatus = self.lastConnectionStatus
            self.lastConnectionStatus = isConnected

            // Update Mode
            self.currentFeedMode = isConnected ? .online : .offline

            // Handle Logic based on Previous Status
            if previousStatus == nil {
                // 👉 App Launch: Only show toast if Offline. Silent if Online.
                if !isConnected { self.showOfflineToast() }
            } else {
                // 👉 Runtime Change
                if isConnected {
                    self.showBackOnlineAlert()
                } else {
                    self.showOfflineToast()
                }
            }
        }
    }

    private func showBackOnlineAlert() {
        if presentedViewController is UIAlertController { return }

        let alert = UIAlertController(title: "Back Online 🟢", message: "You are connected now. Fetch latest news?", preferredStyle: .alert)
        let fetchAction = UIAlertAction(title: "Fetch", style: .default) { [weak self] _ in
            guard let self else { return }
            self.refreshData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(fetchAction)
        present(alert, animated: true)
    }

    private func showOfflineToast() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            LoaderManager.shared.stopLoader()
            self.refreshControl.endRefreshing()
            HapticManager.shared.play(.warning)

            let toast = UILabel(frame: CGRect(x: 40, y: self.view.frame.height - 100, width: self.view.frame.width - 80, height: 70))
            toast.backgroundColor = .systemRed
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
        if NetworkMonitor.shared.isConnected {
            currentFeedMode = .online
            bannerContainerView.isHidden = false

            // 🔥 Pro Logic: Fetch Ads BEFORE fetching News
            // We fetch a batch of 3 ads to keep the pool fresh for the upcoming news list
            GoogleAdClassManager.shared.fetchNativeAdsBatch(rootVC: self, count: FeedConfig.adBatchSize) { [weak self] in
                guard let self = self else { return }
                // Once ads are ready (or failed), fetch news
                DispatchQueue.main.async {
                    self.viewModel.fetchNewsApi(page: self.currentPage)
                }
            }
        } else {
            // Offline Logic
            bannerContainerView.isHidden = true
            currentFeedMode = .offline
            if viewModel.articles.isEmpty { showOfflineToast() }
        }
    }

    // Fetch data from Core Data
    private func fetchOfflineData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentFeedMode = .offline

            // Get raw articles from DB
            let savedArticles = DBManager.shared.fetchCoreDataNews()
            self.viewModel.articles = savedArticles

            // Process Feed (Offline Mode = No Ads)
            self.viewModel.refreshFeed(mode: .offline)

            self.tblNewsList.reloadData()
        }
    }

    // MARK: - Actions

    @objc private func refreshData() {
        currentPage = 1
        HapticManager.shared.play(.light)
        loadFreshData()
    }

    // MARK: - ViewModel Bindings

    private func setupBindings() {
        viewModel.eventHandler = { [weak self] event in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch event {
                case .loading:
                    self.isLoading = true
                    if self.viewModel.articles.isEmpty {
                        LoaderManager.shared.startLoader(message: "Fetching latest news...")
                    } else if self.currentPage > 1 {
                        self.tblNewsList.showBottomLoader()
                    }

                case .stopLoading:
                    self.isLoading = false
                    LoaderManager.shared.stopLoader()
                    self.tblNewsList.hideBottomLoader()
                    self.refreshControl.endRefreshing()

                case .dataLoaded:
                    self.isLoading = false
                    self.handleDataLoaded()

                case let .network(error):
                    self.isLoading = false
                    print("Network Error: \(error?.localizedDescription ?? "Unknown")")
                    self.showAlert(title: "Error", message: error?.localizedDescription ?? "Something went wrong")
                }
            }
        }
    }

    // MARK: - Handle Data Sync

    private func handleDataLoaded() {
        totalResultsCount = viewModel.newsDataModel?.totalResults ?? 0
        // Pagination Math: 15 items per page
        totalPage = Int(ceil(Double(totalResultsCount) / 15.0))

        // --- OPTIMIZATION: If Page 1 data matches DB, skip save ---
        if currentPage == 1 {
            let savedArticles = DBManager.shared.fetchCoreDataNews()
            if savedArticles == viewModel.articles {
                print("✅ Data is up to date. Skipping DB Save.")
                LoaderManager.shared.stopLoader()
                refreshControl.endRefreshing()
                tblNewsList.reloadData() // Just reload to show Ads if any
                return
            }
        }

        // Save fresh data to DB
        if currentPage == 1 {
            DBManager.shared.deleteAllData { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async { self.saveAndRefresh() }
            }
        } else {
            saveAndRefresh()
        }
    }

    private func saveAndRefresh() {
        // We save ONLY raw articles to Core Data (No Ads)
        DBManager.shared.saveNewsCoreData(newData: viewModel.articles) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                LoaderManager.shared.stopLoader()

                // Reload Table with Mixed Data (News + Ads)
                self.tblNewsList.reloadData()
                HapticManager.shared.play(.success)
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension NewsHomeVC: UITableViewDataSource, UITableViewDelegate {
    // ✅ Use 'feedItems' (Merged List)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.feedItems[indexPath.row]

        switch item {
        case let .news(article):
            // 📰 News Cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTVC", for: indexPath) as? NewsTVC else {
                return UITableViewCell()
            }
            cell.article = article

            // Actions
            cell.onReadButtonTapped = { [weak self] in
                guard let self = self else { return }
                self.navigateToWebView(url: article.articleUrl)
            }

            cell.onImageTapped = { [weak self] imgView in
                guard let self = self else { return }
                guard let img = imgView.image else { return }
                let hdUrl = URL(string: article.imageUrl ?? "")
                let info = HpdImageInfo(image: img, imageMode: .aspectFit, imageHD: hdUrl)
                let trans = HpdTransitionInfo(fromView: imgView)
                let viewer = HpdImageViewerController(imageInfo: info, transitionInfo: trans)
                self.present(viewer, animated: true)
            }
            return cell

        case let .ad(nativeAd):
            // 📣 Ad Cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NativeAdTVC", for: indexPath) as? NativeAdTVC else {
                return UITableViewCell()
            }
            // Configure the Native Ad
            cell.configure(with: nativeAd)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Only handle selection for News items
        if case let .news(article) = viewModel.feedItems[indexPath.row] {
            let nextVC = storyboard?.instantiateViewController(withIdentifier: "NewsDetailsVC") as! NewsDetailsVC
            nextVC.article = article
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

    // MARK: - Pagination Logic with Ads 🔄

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastRow = indexPath.row == viewModel.feedItems.count - 1

        // Only fetch if online, not loading, and pages remain
        if isLastRow && currentPage < totalPage && !isLoading && currentFeedMode == .online {
            currentPage += 1
            HapticManager.shared.play(.selection)

            // 1. Fetch NEW Ads batch first (to keep pool fresh)
            GoogleAdClassManager.shared
                .fetchNativeAdsBatch(rootVC: self, count: FeedConfig.adBatchSize) { [weak self] in
                guard let self = self else { return }
                // 2. Then Fetch News Page
                self.viewModel.fetchNewsApi(page: self.currentPage)
            }
        }
    }

    private func navigateToWebView(url: String?) {
        guard let urlStr = url, !urlStr.isEmpty else { return }

        if NetworkMonitor.shared.isConnected {
            let nextVC = storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
            nextVC.strNewsUrl = urlStr
            HapticManager.shared.play(.light)
            navigationController?.pushViewController(nextVC, animated: true)
        } else {
            HapticManager.shared.play(.error)
            showOfflineToast()
        }
    }
}
