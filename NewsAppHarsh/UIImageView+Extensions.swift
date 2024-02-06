//
//  UIImageView+Extensions.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import UIKit
//import Kingfisher

extension UIImageView{
    /*
    func setImage(with urlString : String){
        
        guard let url = URL(string: urlString) else { return }
        
        let resource = KF.ImageResource(downloadURL: url, cacheKey: urlString)
        
        self.kf.indicatorType = .activity
        
        self.kf.setImage(with : resource,placeholder: UIImage(named: "placeholder"))
        
    }*/
    func downloadImage(fromURL url: String) {
        ApiManager.shared.downloadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async { self.image = image }
        }
    }
}
