//
//  NewsDetailsVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit

class NewsDetailsVC: UIViewController {
    
    //MARK: -  @IBOutlet
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgNews: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblAuthor: UILabel!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var btnWebView: UIButton!
    
    //MARK: -  Properties
    var article : Articles?
    
    
    //MARK: -  ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
         
        configureNewsData()
        
        let pictureTap = UITapGestureRecognizer(target: self, action: #selector(openImage))
        self.imgNews.isUserInteractionEnabled = true
        self.imgNews.addGestureRecognizer(pictureTap)
         
    }
     
    @objc func openImage(_ sender: UITapGestureRecognizer) {
        let imageInfo = HpdImageInfo(image: imgNews.image ?? UIImage(), imageMode: .aspectFit)
        let transitionInfo = HpdTransitionInfo(fromView: sender.view ?? UIView())
        let imageViewer = HpdImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)
        imageViewer.dismissCompletion = {
            print("image dissmissed")
        }
        present (imageViewer, animated: true)
         
    }
     
    
    func configureNewsData(){
        lblTitle.text = article?.title ?? ""
        lblDesc.text = article?.myDescription ?? ""
        
        let outputDateString = Constant.shared.convertDateFormat(from: (article?.publishedAt ?? ""), fromFormat: "yyyy-MM-dd'T'HH:mm:ssZ", toFormat: "dd MMM, yyyy hh:mm a")
        
        lblDate.text = "Published on : \(outputDateString ?? "")"
        
        if let authorVal = article?.author,!(authorVal.isEmpty){
            lblAuthor.text = "Published By : \(authorVal)"
        }else{
            lblAuthor.text = "Unknown Author"
        }
         
        lblContent.text = article?.content ?? ""
        
         
        if let imgVal = article?.urlToImage,!(imgVal.isEmpty){
            imgNews.setImage(with: imgVal)
        }else{
            imgNews.image = UIImage(named: "placeholder")
        }
    }
    
    //MARK: -  Buttons Actions
    @IBAction func btnWebViewTapped(_ sender: UIButton) {
        
        if NetworkReachability.shared.isNetworkAvailable() {
            let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
            
            if let url = article?.url{
                Constant.shared.lightHapticFeedBack()
                nextVC.strNewsUrl = url
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        } else {
            Constant.shared.heavyHapticFeedBack()
            Constant.shared.showAlertHandler(title: "Oops! It seems like you're offline", message: "Please check your internet connection and try again later.", view: self) { alert in
                self.dismiss(animated: true)
            }
        }
        
        
        
    }
    
    
}
