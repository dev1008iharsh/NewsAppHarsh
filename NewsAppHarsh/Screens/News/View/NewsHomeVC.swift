//
//  NewsListHomeVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import UIKit

final class NewsHomeVC: UIViewController {
    // MARK: - Outlets

    @IBOutlet private var tblNewsList: UITableView!

    // MARK: - Properties

    private let viewModel = NewsViewModel()
    private let refreshControl = UIRefreshControl()

    // Pagination Properties
    private var articles = [Article]()
    private var totalResultsCount = 0
    private var totalPage = 1
    private var currentPage = 1
    private var isLoading = false

    private var lastConnectionStatus: Bool?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNetworkObserver() // 📡 Start listening to network changes

        // Load Offline Data (Instant)
        fetchOfflineData()

        // Try Fetching Fresh Data
        loadFreshData()
    }

    // MARK: - Setup UI

    private func setupUI() {
        title = "Breaking News"

        tblNewsList.register(UINib(nibName: "NewsTVC", bundle: nil), forCellReuseIdentifier: "NewsTVC")
        tblNewsList.refreshControl = refreshControl
        tblNewsList.dataSource = self
        tblNewsList.delegate = self

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    // MARK: - Network Observer (Pro Feature 🚀)

    private func setupNetworkObserver() {
        NetworkMonitor.shared.onStatusChange = { [weak self] isConnected in
            guard let self = self else { return }

            if self.lastConnectionStatus == isConnected {
                return
            }

            let previousStatus = self.lastConnectionStatus

            self.lastConnectionStatus = isConnected

            // 2. Handle Logic based on Previous Status
            if previousStatus == nil {
                // 👉 App Launch (First Time)
                // જો એપ ખુલતાની સાથે જ Offline હોય, તો ટોસ્ટ બતાવો.
                // જો Online હોય, તો કઈ જ કરવાની જરૂર નથી (Silent).
                if !isConnected {
                    self.showOfflineToast()
                }
            } else {
                // 👉 Runtime Change (State Changed)
                if isConnected {
                    // Offline ➔ Online
                    self.showBackOnlineAlert()
                } else {
                    // Online ➔ Offline
                    self.showOfflineToast()
                }
            }
        }
    }

    private func showBackOnlineAlert() {
        // Prevent alert stacking if one is already presented
        if presentedViewController is UIAlertController { return }

        let alert = UIAlertController(title: "Back Online 🟢", message: "You are connected to the internet. Do you want to fetch the latest news?", preferredStyle: .alert)

        let fetchAction = UIAlertAction(title: "Fetch News", style: .default) { [weak self] _ in
            self?.refreshData() // Call API
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(fetchAction)

        present(alert, animated: true)
    }

    // MARK: - Data Loading Logic

    private func loadFreshData() {
        if NetworkMonitor.shared.isConnected {
            LoaderManager.shared.startLoader(message: "Fetching latest news")
            viewModel.fetchNewsApi(page: currentPage)
        } else if articles.isEmpty {
            showOfflineToast()
        }
    }

    // MARK: - Actions

    @objc private func refreshData() {
        currentPage = 1
        HapticManager.shared.play(.light)
        loadFreshData()
    }

    private func showOfflineToast() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Stop loaders if running
            LoaderManager.shared.stopLoader()
            self.refreshControl.endRefreshing()
            HapticManager.shared.play(.warning)

            let toast = UILabel(
                frame: CGRect(
                    x: 40,
                    y: self.view.frame.height - 80,
                    width: self.view.frame.width - 80,
                    height: 50
                )
            )
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

    // Fetch data from Core Data
    private func fetchOfflineData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.articles = DBManager.shared.fetchCoreDataNews()
            self.tblNewsList.reloadData()
        }
    }

    // MARK: - ViewModel Bindings

    private func setupBindings() {
        viewModel.eventHandler = { [weak self] event in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch event {
                case .loading:
                    self.isLoading = true
                    if self.articles.isEmpty {
                        LoaderManager.shared.startLoader(message: "Updating latest news...")
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
                    // Optional: Show alert only if it's a critical failure, otherwise toast is enough
                    self.showAlert(title: "❌ Unable to get latest data", message: "Network Error: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }

    // MARK: - Handle Data Sync (Optimized 🚀)

    private func handleDataLoaded() {
        totalResultsCount = viewModel.newsDataModel?.totalResults ?? 0
        totalPage = Int(ceil(Double(totalResultsCount) / 20))
        print("totalPagetotalPagetotalPages",totalPage)

        let newArticles = viewModel.articles

        // --- OPTIMIZATION START ---
        if currentPage == 1 {
            // Check if current Local DB data matches exactly with New API data
            if articles == newArticles {
                print("✅ Data is exactly same. Skipping Database Operations.")
                LoaderManager.shared.stopLoader()
                refreshControl.endRefreshing()
                return
            }
        }

        if currentPage == 1 {
            // Delete Old Data
            DBManager.shared.deleteAllData { [weak self] in
                DispatchQueue.main.async {
                    LoaderManager.shared.startLoader(message: "Syncing News Data...")
                    self?.saveAndRefresh()
                }
            }
        } else {
            // Append Data
            DispatchQueue.main.async {
                self.saveAndRefresh()
            }
        }
    }

    private func saveAndRefresh() {
        DBManager.shared.saveNewsCoreData(newData: viewModel.articles) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }

                LoaderManager.shared.stopLoader()
                self.fetchOfflineData()
                HapticManager.shared.play(.success)
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension NewsHomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTVC", for: indexPath) as? NewsTVC else {
            return UITableViewCell()
        }

        cell.article = articles[indexPath.row]

        cell.onReadButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.navigateToWebView(url: cell.article?.articleUrl)
        }

        cell.onImageTapped = { [weak self] tappedImageView in
            guard let self = self else { return }
            guard let image = tappedImageView.image else { return }

            let hdUrl = URL(string: cell.article?.imageUrl ?? "")
            let imageInfo = HpdImageInfo(image: image, imageMode: .aspectFit, imageHD: hdUrl)
            let transitionInfo = HpdTransitionInfo(fromView: tappedImageView)

            let imageViewer = HpdImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)
            self.present(imageViewer, animated: true)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "NewsDetailsVC") as! NewsDetailsVC
        nextVC.article = articles[indexPath.row]
        navigationController?.pushViewController(nextVC, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastRow = indexPath.row == articles.count - 1

        if isLastRow && currentPage < totalPage && !isLoading{
            currentPage += 1
            HapticManager.shared.play(.selection)
            viewModel.fetchNewsApi(page: currentPage)
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
