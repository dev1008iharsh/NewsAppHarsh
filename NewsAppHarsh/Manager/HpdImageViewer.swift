//
//  HpdImageViewer.swift
//  NewsAppHarsh
//
//  Created by Harsh on 26/01/26.
//

import UIKit

// MARK: - 1. Configuration Models

public struct HpdImageInfo: Sendable {
    public enum ImageMode: Int, Sendable {
        case aspectFit = 1, aspectFill = 2
    }

    public let image: UIImage
    public let imageMode: ImageMode
    public let imageHD: URL?

    public var contentMode: UIView.ContentMode {
        return UIView.ContentMode(rawValue: imageMode.rawValue) ?? .scaleAspectFit
    }

    public init(image: UIImage, imageMode: ImageMode, imageHD: URL? = nil) {
        self.image = image
        self.imageMode = imageMode
        self.imageHD = imageHD
    }

    func calculateRect(_ size: CGSize) -> CGRect {
        guard image.size.width > 0, image.size.height > 0 else { return .zero }
        let widthRatio = size.width / image.size.width
        let heightRatio = size.height / image.size.height

        switch imageMode {
        case .aspectFit:
            return CGRect(origin: .zero, size: size)
        case .aspectFill:
            let scale = max(widthRatio, heightRatio)
            return CGRect(x: 0, y: 0, width: image.size.width * scale, height: image.size.height * scale)
        }
    }

    func calculateMaxZoom(_ size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 2.0 }
        return max(2.0, max(image.size.width / size.width, image.size.height / size.height))
    }
}

@MainActor
public class HpdTransitionInfo {
    public var duration: TimeInterval = 0.35
    public var canSwipe: Bool = true
    weak var fromView: UIView?
    fileprivate var convertedRect: CGRect?

    public init(fromView: UIView) { self.fromView = fromView }
    public init(fromRect: CGRect) { convertedRect = fromRect }
}

// MARK: - 2. Main Controller

@MainActor
public class HpdImageViewerController: UIViewController {
    // Properties
    private let imageInfo: HpdImageInfo
    private var transitionInfo: HpdTransitionInfo?

    public let imageView = UIImageView()
    public let scrollView = UIScrollView()
    public var dismissCompletion: (() -> Void)?

    // Logic State
    private var panStartOrigin: CGPoint?
    fileprivate var panViewAlpha: CGFloat = 1

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        // Using SF Symbol for a modern look
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.alpha = 0.9
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleCloseButton), for: .touchUpInside)
        return btn
    }()

    // MARK: Init

    public init(imageInfo: HpdImageInfo, transitionInfo: HpdTransitionInfo? = nil) {
        self.imageInfo = imageInfo
        self.transitionInfo = transitionInfo
        super.init(nibName: nil, bundle: nil)
        setupTransition()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func setupTransition() {
        guard let info = transitionInfo, let fromView = info.fromView, let refView = fromView.superview else { return }
        info.convertedRect = refView.convert(fromView.frame, to: nil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    // MARK: Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        setupCloseButton()
        // Async HD Image Loading
        if let hdURL = imageInfo.imageHD {
            Task { await loadHDImage(from: hdURL) }
        }
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        imageView.frame = imageInfo.calculateRect(view.bounds.size)
        scrollView.frame = view.bounds
        scrollView.contentSize = imageView.bounds.size
        scrollView.maximumZoomScale = imageInfo.calculateMaxZoom(scrollView.bounds.size)
    }

    // MARK: Setups

    private func setupUI() {
        view.backgroundColor = .black

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        imageView.image = imageInfo.image
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
    }

    private func setupGestures() {
        let single = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
        let double = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
        double.numberOfTapsRequired = 2
        single.require(toFail: double)

        scrollView.addGestureRecognizer(single)
        scrollView.addGestureRecognizer(double)

        if transitionInfo?.canSwipe == true {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
            pan.delegate = self
            scrollView.addGestureRecognizer(pan)
        }
    }

    private func setupCloseButton() {
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            // Top Right Corner Position
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func loadHDImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                imageView.image = image
                view.layoutIfNeeded()
            }
        } catch { print("HD Load Error: \(error)") }
    }

    // MARK: Actions

    @objc private func onSingleTap() {
        dismiss(animated: true, completion: dismissCompletion)
    }

    @objc private func handleCloseButton() {
        // Haptic feedback for better feel
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        dismiss(animated: true, completion: dismissCompletion)
    }

    @objc private func onDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1.0 {
            let p = sender.location(in: scrollView)
            scrollView.zoom(to: CGRect(x: p.x - 40, y: p.y - 40, width: 80, height: 80), animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }

    @objc private func onPan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)

        switch sender.state {
        case .began:
            panStartOrigin = scrollView.center
        case .changed:
            guard let origin = panStartOrigin else { return }
            scrollView.center = CGPoint(x: origin.x + translation.x, y: origin.y + translation.y)
            panViewAlpha = 1 - (abs(translation.y) / view.bounds.height)
            view.backgroundColor = UIColor(white: 0.0, alpha: panViewAlpha)
        case .ended:
            if panViewAlpha < 0.75 || abs(sender.velocity(in: view).y) > 1000 {
                dismiss(animated: true, completion: dismissCompletion)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.scrollView.center = self.panStartOrigin ?? self.view.center
                    self.view.backgroundColor = .black
                }
                panViewAlpha = 1.0
            }
        default: break
        }
    }
}

// MARK: - Delegates

extension HpdImageViewerController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center image logic if needed, usually auto-handled by contentInset
    }
}

extension HpdImageViewerController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard let pan = gesture as? UIPanGestureRecognizer else { return true }
        if scrollView.zoomScale != 1.0 { return false }
        if imageInfo.imageMode == .aspectFill {
            if scrollView.contentOffset.x > 0 || pan.translation(in: view).x <= 0 { return false }
        }
        return true
    }
}

extension HpdImageViewerController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let info = transitionInfo else { return nil }
        return HpdAnimator(imageInfo: imageInfo, transitionInfo: info, isPresenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let info = transitionInfo else { return nil }
        return HpdAnimator(imageInfo: imageInfo, transitionInfo: info, isPresenting: false)
    }
}

// MARK: - 3. Animator

@MainActor
final class HpdAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let imageInfo: HpdImageInfo
    let transitionInfo: HpdTransitionInfo
    let isPresenting: Bool

    init(imageInfo: HpdImageInfo, transitionInfo: HpdTransitionInfo, isPresenting: Bool) {
        self.imageInfo = imageInfo
        self.transitionInfo = transitionInfo
        self.isPresenting = isPresenting
    }

    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionInfo.duration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        let tempMask = UIView()
        tempMask.backgroundColor = .black

        let tempImage = UIImageView(image: imageInfo.image)
        tempImage.contentMode = imageInfo.contentMode
        tempImage.layer.cornerRadius = transitionInfo.fromView?.layer.cornerRadius ?? 0
        tempImage.layer.masksToBounds = true

        container.addSubview(tempMask)
        container.addSubview(tempImage)

        if isPresenting {
            guard let toVC = context.viewController(forKey: .to) as? HpdImageViewerController else { return }
            transitionInfo.fromView?.alpha = 0
            toVC.view.layoutIfNeeded()

            tempMask.alpha = 0
            tempMask.frame = toVC.view.bounds
            tempImage.frame = transitionInfo.convertedRect ?? .zero

            UIView.animate(withDuration: transitionDuration(using: context)) {
                tempMask.alpha = 1
                tempImage.frame = toVC.imageView.frame
            } completion: { _ in
                tempMask.removeFromSuperview()
                tempImage.removeFromSuperview()
                container.addSubview(toVC.view)
                context.completeTransition(true)
            }
        } else {
            guard let fromVC = context.viewController(forKey: .from) as? HpdImageViewerController else { return }
            fromVC.view.removeFromSuperview()

            tempMask.alpha = fromVC.panViewAlpha
            tempMask.frame = fromVC.view.bounds

            // Match current scroll offset
            tempImage.frame = CGRect(
                x: -fromVC.scrollView.contentOffset.x,
                y: -fromVC.scrollView.contentOffset.y,
                width: fromVC.scrollView.contentSize.width,
                height: fromVC.scrollView.contentSize.height
            )

            UIView.animate(withDuration: transitionDuration(using: context)) {
                tempMask.alpha = 0
                tempImage.frame = self.transitionInfo.convertedRect ?? .zero
            } completion: { _ in
                tempMask.removeFromSuperview()
                tempImage.removeFromSuperview()
                self.transitionInfo.fromView?.alpha = 1
                context.completeTransition(true)
            }
        }
    }
}
