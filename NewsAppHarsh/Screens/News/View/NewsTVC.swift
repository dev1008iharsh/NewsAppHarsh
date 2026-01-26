//
//  NewsTVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//
import UIKit

final class NewsTVC: UITableViewCell {
    // MARK: - @IBOutlet

    @IBOutlet var btnRead: UIButton!
    @IBOutlet private var lblDateNews: UILabel!
    @IBOutlet private var lblAuthorNews: UILabel!
    @IBOutlet private var lblTitleNews: UILabel!
    @IBOutlet private var imgNews: UIImageView!
    @IBOutlet private var bgView: UIView!

    // MARK: - Properties

    var article: Article? {
        didSet {
            configureNewsData()
        }
    }

    var onReadButtonTapped: (() -> Void)?
    var onImageTapped: ((UIImageView) -> Void)?

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        lblDateNews.text = nil
        lblAuthorNews.text = nil
        lblTitleNews.text = nil
        imgNews.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupTapMethods()
    }

    private func setupTapMethods() {
        btnRead.addTarget(self, action: #selector(btnReadAction), for: .touchUpInside)

        imgNews.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imgNews.addGestureRecognizer(tap)
    }

    // MARK: - Configuration

    private func configureNewsData() {
        guard let article = article else { return }

        lblTitleNews.text = article.title
        lblAuthorNews.text = (article.author?.isEmpty == false) ? article.author : "Unknown Author"

        // Date Formatting
        lblDateNews.text = AppUtils.shared.format(
            dateString: article.publishedAt ?? "",
            from: "yyyy-MM-dd'T'HH:mm:ssZ",
            to: "dd MMM, yyyy hh:mm a"
        )

        // Image Loading
        if let imgUrl = article.imageUrl {
            imgNews.downloadImage(fromURL: imgUrl, placeholder: UIImage(named: "placeholder"))
        } else {
            imgNews.image = UIImage(named: "placeholder")
        }
    }

    @objc private func btnReadAction() {
        HapticManager.shared.play(.light) // Optional Haptic
        onReadButtonTapped?()
    }

    @objc private func imageTapped() {
        HapticManager.shared.play(.selection)
        onImageTapped?(imgNews)
    }
}
