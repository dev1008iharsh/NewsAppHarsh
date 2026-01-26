//
//  NewsListHomeVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import UIKit
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()

        fetchOfflineData()
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

    // MARK: - Data Loading Logic

    private func loadFreshData() {
        if NetworkMonitor.shared.isConnected {
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
            LoaderManager.shared.stopLoader()
            HapticManager.shared.play(.warning)

            guard let self = self else { return }

            let toast = UILabel(frame: CGRect(x: 40, y: 150, width: self.view.frame.width - 80, height: 40))
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
                    if self.articles.isEmpty {
                        LoaderManager.shared.startLoader(message: "Updating...")
                    } else if self.currentPage > 1 {
                        self.tblNewsList.showBottomLoader()
                    }

                case .stopLoading:
                    LoaderManager.shared.stopLoader()
                    self.tblNewsList.hideBottomLoader()
                    self.refreshControl.endRefreshing()

                case .dataLoaded:
                    self.handleDataLoaded()

                case let .network(error):
                    print("Network Error: \(error?.localizedDescription ?? "Unknown")")
                    self.showAlert(title: "Unable to get data from internet", message: "Network Error: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }

    // MARK: - Handle Data Sync (Optimized 🚀)

    private func handleDataLoaded() {
        totalResultsCount = viewModel.newsDataModel?.totalResults ?? 0
        totalPage = Int(ceil(Double(totalResultsCount) / 20.0))

        let newArticles = viewModel.articles

        // --- OPTIMIZATION START ---
        // જો Page 1 હોય અને નવો ડેટા == જૂનો ડેટા હોય, તો કઈ જ કરવાની જરૂર નથી.
        if currentPage == 1 {
            // Check if current Local DB data matches exactly with New API data
            if articles == newArticles {
                print("✅ Data is exactly same. Skipping Database Operations.")
                LoaderManager.shared.stopLoader()
                refreshControl.endRefreshing()
                return // અહીંથી જ પાછા વળી જાઓ! 🛑
            }
        }
        // --- OPTIMIZATION END ---

        // જો ડેટા અલગ હોય, તો જ આગળ વધો...
        DispatchQueue.main.async {
            LoaderManager.shared.startLoader(message: "Syncing Data...")
        }

        if currentPage == 1 {
            // Delete Old Data
            DBManager.shared.deleteAllData { [weak self] in
                DispatchQueue.main.async {
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

            // Direct Call with URL
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

        if isLastRow && currentPage < totalPage {
            currentPage += 1
            HapticManager.shared.play(.selection)
            viewModel.fetchNewsApi(page: currentPage)
        }
    }

    private func navigateToWebView(url: String?) {
        // 1. URL Safe Check
        guard let urlStr = url, !urlStr.isEmpty else { return }

        // 2. Internet Check
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
