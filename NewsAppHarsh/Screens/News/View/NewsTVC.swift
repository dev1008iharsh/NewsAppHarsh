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
        
        lblDateNews.text = article?.publishedAt
        lblAuthorNews.text = article?.author ?? "Unknown Author"
        lblTitleNews.text = article?.title
        if let img = article?.urlToImage{
            imgNews.setImage(with: img)
        }
       
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
 
    }
    
}
