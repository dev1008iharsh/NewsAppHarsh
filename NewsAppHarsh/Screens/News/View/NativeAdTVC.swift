//
//  NativeAdTVC.swift
//  NewsAppHarsh
//
//  Created by Harsh on 28/01/26.
//

import GoogleMobileAds
import UIKit

import GoogleMobileAds
import UIKit

class NativeAdTVC: UITableViewCell {
    // MARK: - IBOutlets

    @IBOutlet var nativeAdView: NativeAdView!

    // Media View ( Image  Video )
    @IBOutlet var mediaView: MediaView!

    // Icon Image (App Icon  Logo)
    @IBOutlet var iconImageView: UIImageView!

    // Text Labels
    @IBOutlet var headlineLabel: UILabel! // Main Title
    @IBOutlet var bodyLabel: UILabel! // Description
    @IBOutlet var advertiserLabel: UILabel! // Advertiser Name / Rating
    @IBOutlet var adBadgeLabel: UILabel! //  "Ad" label (Required by policy)

    // Action Button
    @IBOutlet var callToActionButton: UIButton! // "Install", "Open", etc.

    @IBOutlet var starRatingLabel: UILabel!

    @IBOutlet var constraintMediaViewHeight: NSLayoutConstraint!
    @IBOutlet var constraintMediaViewBottomSpacing: NSLayoutConstraint!

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    /// Resets the cell state before reuse to prevent showing old data/ads.
    override func prepareForReuse() {
        super.prepareForReuse()

        // Remove the ad binding to free up resources and avoid memory leaks.
        nativeAdView.nativeAd = nil

        // Reset UI elements to default state
        mediaView.isHidden = true
        iconImageView.image = nil
        headlineLabel.text = nil
        bodyLabel.text = nil
    }

    // MARK: - UI Setup

    private func setupUI() {
        
        iconImageView.layer.cornerRadius = 5
        nativeAdView.layer.cornerRadius = 15
        mediaView.layer.cornerRadius = 10
        
        // Configure basic typography and styling
        headlineLabel.font = .systemFont(ofSize: 16, weight: .bold)
        bodyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = .secondaryLabel

        // Button Styling
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.clipsToBounds = true
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.setTitleColor(.white, for: .normal)

        // Important: Disable user interaction on the button so the GADNativeAdView handles the tap.
        // This ensures clicks are registered correctly by the SDK.
        callToActionButton.isUserInteractionEnabled = false
    }

    // MARK: - Configuration

    func configure(with nativeAd: NativeAd) {
        // 1. Media View Setup & Logic 📏

        nativeAdView.mediaView = mediaView
        mediaView.mediaContent = nativeAd.mediaContent

        // Height Logic:  video/image then height
        if nativeAd.mediaContent.aspectRatio > 0 {
            constraintMediaViewHeight.constant = 150
            constraintMediaViewBottomSpacing.constant = 10
            mediaView.isHidden = false
        } else {
            constraintMediaViewHeight.constant = 0
            constraintMediaViewBottomSpacing.constant = 0
            mediaView.isHidden = true
        }

        // 2. Headline
        nativeAdView.headlineView = headlineLabel
        headlineLabel.text = nativeAd.headline

        // 3. Icon
        nativeAdView.iconView = iconImageView
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil

        // 4. Body
        nativeAdView.bodyView = bodyLabel
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil

        // 5. Call to Action Button
        nativeAdView.callToActionView = callToActionButton
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction == nil
        callToActionButton.isUserInteractionEnabled = false // Tap GADNativeAdView પર pass કરવા

        // 6. Advertiser
        nativeAdView.advertiserView = advertiserLabel
        advertiserLabel.text = nativeAd.advertiser
        advertiserLabel.isHidden = nativeAd.advertiser == nil
      
        adBadgeLabel.isHidden = false
       
        // 8. Star Rating
        nativeAdView.starRatingView = starRatingLabel
        // rating scale 5 હોય છે, એટલે આપણે double value string માં convert કરીએ
        if let rating = nativeAd.starRating {
            starRatingLabel.text = "\(rating) ★"
            starRatingLabel.isHidden = false
        } else {
            starRatingLabel.isHidden = true
        }

        nativeAdView.nativeAd = nativeAd

        layoutIfNeeded()
    }
}
