//
//  WebViewVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import UIKit
import WebKit

final class WebViewVC: UIViewController {
    // MARK: - Outlets

    @IBOutlet private var webView: WKWebView!

    // MARK: - Properties

    var strNewsUrl = ""

    // Create Progress Bar Programmatically
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.trackTintColor = .tertiarySystemGroupedBackground
        progress.progressTintColor = .systemIndigo // Change color as per your theme
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        setupObservers() // Progress bar logic
        loadUrl()
    }

    // Clean up observers to prevent crashes
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        webView.navigationDelegate = nil
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    // MARK: - Setup UI

    private func setupUI() {
        // 1. Add Share & Refresh Button to Navigation Bar
        let shareBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped))

        // Add Back/Forward Arrows if needed, generally Share/Refresh is enough for News
        navigationItem.rightBarButtonItems = [refreshBtn, shareBtn]

        // 2. Add Progress Bar below Navigation Bar
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 5),
        ])
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        // Enable Swipe gestures for Back/Forward
        webView.allowsBackForwardNavigationGestures = true
    }

    // MARK: - Observers (KVO)

    private func setupObservers() {
        // Observe 'estimatedProgress' to update Progress Bar
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)

        // Observe 'title' to update Navigation Title
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let progress = Float(webView.estimatedProgress)
            progressView.setProgress(progress, animated: true)

            // Hide progress bar when loading finishes
            if progress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut) {
                    self.progressView.alpha = 0
                }
            } else {
                progressView.alpha = 1
            }
        } else if keyPath == "title" {
            // Update ViewController title with Web Page Title
            title = webView.title
        }
    }

    // MARK: - Logic

    private func loadUrl() {
        guard let url = URL(string: strNewsUrl) else { return }
        // LoaderManager can be removed if using Progress Bar, or keep it for initial start
        // LoaderManager.shared.startLoader(message: "Loading...")
        // I prefer Progress Bar for WebViews as it looks cleaner.

        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - Actions

    @objc private func shareTapped() {
        guard let url = webView.url else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    @objc private func refreshTapped() {
        webView.reload()
    }
}

// MARK: - WKNavigationDelegate

extension WebViewVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Haptic Feedback only when page fully loads
        HapticManager.shared.play(.success)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web Error: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Handle loading error (e.g. No Internet)
        print("Loading Error: \(error.localizedDescription)")

        // Show Alert Logic Here (Optional)
    }
}
