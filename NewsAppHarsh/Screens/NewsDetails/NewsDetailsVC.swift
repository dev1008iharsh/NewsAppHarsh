//
//  NewsDetailsVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit

class NewsDetailsVC: UIViewController {
   
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgNews: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblAuthor: UILabel!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    
    @IBOutlet weak var btnWebView: UIButton!
    
    var article : Articles?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
       
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureNewsData()
    }
    
    func configureNewsData(){
        lblTitle.text = article?.title ?? ""
        lblDesc.text = article?.description ?? ""
        lblDate.text = article?.publishedAt ?? ""
        lblAuthor.text = "Published By : \(article?.author ?? ("Unknown Author"))" 
        lblContent.text = article?.content ?? ""
        
        if let img = article?.urlToImage{
            imgNews.setImage(with: img)
        }
    }
     
    
    @IBAction func btnWebViewTapped(_ sender: UIButton) {
        
        let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
        
        if let url = article?.url{
            nextVC.strNewsUrl = url
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        
    }
    
    
}
