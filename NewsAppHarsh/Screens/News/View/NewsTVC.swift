//
//  NewsTVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit

class NewsTVC: UITableViewCell {

    @IBOutlet weak var btnWeb: UIButton!
    @IBOutlet weak var lblDateNews: UILabel!
    @IBOutlet weak var lblAuthorNews: UILabel!
    @IBOutlet weak var lblTitleNews: UILabel!
    @IBOutlet weak var imgNews: UIImageView!
    @IBOutlet weak var bgView: UIView!
    
    
    var article : Articles?{
        didSet{
            configureNewsData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    func configureNewsData(){
        
        
        let outputDateString = Constant.shared.convertDateFormat(from: (article?.publishedAt ?? ""), fromFormat: "yyyy-MM-dd'T'HH:mm:ssZ", toFormat: "dd MMM, yyyy hh:mm a")
        lblDateNews.text = outputDateString
        
        if let authorVal = article?.author,!(authorVal.isEmpty){
            lblAuthorNews.text = authorVal
        }else{
            lblAuthorNews.text = "Unknown Author"
        }
        
        lblTitleNews.text = article?.title
        if let img = article?.urlToImage{
            imgNews.setImage(with: img)
        }
         
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
 
    }
    
}
