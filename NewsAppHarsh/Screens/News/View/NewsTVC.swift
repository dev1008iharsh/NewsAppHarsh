//
//  NewsTVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit

class NewsTVC: UITableViewCell {

    //MARK: -  @IBOutlet
    @IBOutlet weak var btnWeb: UIButton!
    @IBOutlet weak var lblDateNews: UILabel!
    @IBOutlet weak var lblAuthorNews: UILabel!
    @IBOutlet weak var lblTitleNews: UILabel!
    @IBOutlet weak var imgNews: UIImageView!
    @IBOutlet weak var bgView: UIView!
    
    //MARK: -  Properties
    var article : Articles?{
        didSet{
            configureNewsData()
        }
    }
    
    //MARK: -  LifeCycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.lblDateNews.text = nil
        self.lblAuthorNews.text = nil
        self.lblTitleNews.text = nil
        self.imgNews.image = nil
      
    }
    
    //MARK: -  SetUp Screen
    func configureNewsData(){
         
        let outputDateString = Utility.shared.convertDateFormat(from: (article?.publishedAt ?? ""), fromFormat: "yyyy-MM-dd'T'HH:mm:ssZ", toFormat: "dd MMM, yyyy hh:mm a")
        lblDateNews.text = outputDateString
        
        if let authorVal = article?.author,!(authorVal.isEmpty){
            lblAuthorNews.text = authorVal
        }else{
            lblAuthorNews.text = "Unknown Author"
        }
        
        lblTitleNews.text = article?.title
        
        if let imgVal = article?.urlToImage,!(imgVal.isEmpty){
            //imgNews.setImage(with: imgVal)
            self.imgNews.downloadImage(fromURL: imgVal)
             
        }else{
            imgNews.image = UIImage(named: "placeholder")
        }
        
    }
  
}
