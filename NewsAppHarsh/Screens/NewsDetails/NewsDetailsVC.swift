//
//  NewsDetailsVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import UIKit

final class NewsDetailsVC: UIViewController {
    // MARK: - @IBOutlet

    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var imgNews: UIImageView!
    @IBOutlet private var lblDate: UILabel!
    @IBOutlet private var lblAuthor: UILabel!
    @IBOutlet private var lblDesc: UILabel!
    @IBOutlet private var lblContent: UILabel!
    @IBOutlet private var btnWebView: UIButton!
    
    @IBOutlet var bannerContainerView: UIView!

    // MARK: - Properties

    var article: Article?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBannerInContainer()
        configureNewsData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupUI() {
        title = "Details"
        view.backgroundColor = .tertiarySystemGroupedBackground
        let pictureTap = UITapGestureRecognizer(target: self, action: #selector(openImage))
        imgNews.isUserInteractionEnabled = true
        imgNews.addGestureRecognizer(pictureTap)
    }
    private func setupBannerInContainer() {
        let bannerView = GoogleAdClassManager.shared.getProgrammaticBanner(rootVC: self)
        bannerView.layer.backgroundColor = UIColor.clear.cgColor
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

    @objc private func openImage(_ sender: UITapGestureRecognizer) {
        // 1. Ensure we have an image
        guard let image = imgNews.image else { return }

        // 2. Setup Configuration
        // Note: Pass 'imageHD' here if you have a URL for better quality
        let imageInfo = HpdImageInfo(image: image, imageMode: .aspectFit, imageHD: nil)

        // 3. Setup Transition (From the Image View)
        let transitionInfo = HpdTransitionInfo(fromView: imgNews)

        // 4. Initialize Controller
        let imageViewer = HpdImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)

        // 5. Present
        HapticManager.shared.play(.selection)
        present(imageViewer, animated: true)
    }

    private func configureNewsData() {
        guard let article = article else { return }

        lblTitle.text = article.title
        lblDesc.text = article.descriptionText
        lblContent.text = article.content

        let date = AppUtils.shared.format(
            dateString: article.publishedAt ?? "",
            from: "yyyy-MM-dd'T'HH:mm:ssZ",
            to: "dd MMM, yyyy hh:mm a"
        )
        lblDate.text = "Published: \(date ?? "N/A")"
        lblAuthor.text = "By: \(article.author ?? "Unknown")"

        if let imgUrl = article.imageUrl, !imgUrl.isEmpty {
            imgNews.downloadImage(fromURL: imgUrl)
        } else {
            imgNews.image = UIImage(named: "placeholder")
        }
    }

    @IBAction private func btnWebViewTapped(_ sender: UIButton) {
        if NetworkMonitor.shared.isConnected {
            showRewardAdAlert()
        } else {
            HapticManager.shared.play(.error)
            showAlert(title: "Offline", message: "Internet connection required.")
        }
    }

    func showRewardAdAlert() {
        let alert = UIAlertController(
            title: "Unlock Premium Article 🔓",
            message: "Watch a short video to read the complete article and detailed analysis. Your support helps us provide quality journalism!",
            preferredStyle: .alert
        )

        let watchAction = UIAlertAction(title: "Watch & Read 📰", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.launchRewardedAd()
        }

        let cancelAction = UIAlertAction(
            title: "Maybe Later",
            style: .destructive,
            handler: nil
        )

        alert.addAction(watchAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

    private func launchRewardedAd() {
        GoogleAdClassManager.shared.showRewardedAd(from: self, onReward: { [weak self] in
            guard let self = self else { return }
            print("🎉 Reward earned! Navigating to article...")
            self.openNewsArticle()
        }, onAdNotReady: { [weak self] in
            guard let self = self else { return }
            print("⚠️ Ad not ready. Providing access to avoid negative UX.")
            self.openNewsArticle()
        })
    }

    private func openNewsArticle() {
        guard let url = article?.articleUrl,
              let nextVC = storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as? WebViewVC else { return }

        nextVC.strNewsUrl = url
        HapticManager.shared.play(.light)
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
