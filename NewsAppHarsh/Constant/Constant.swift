//
//  Constant.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import Foundation
import UIKit


class Constant{
    static let shared = Constant()
    private init(){}
    
    let authKey = "467ec62e59864e5ab75a84be5287afee"
    
    func showLoader(_ show: Bool, loadingText : String = "") {
         
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {return }
        guard let _ = windowScene.windows.last else { return }
        windowScene.keyWindow?.viewWithTag(1200)
        //UIApplication.shared.window[0].viewWithTag(1200)
        let existingView = windowScene.keyWindow?.viewWithTag(1200)
        
        if show {
            if existingView != nil {
                return
            }
            let loadingView =  makeLoadingView(withFrame: UIScreen.main.bounds, loadingText: loadingText)
            loadingView?.tag = 1200
            windowScene.keyWindow?.addSubview(loadingView!)
        } else {
            existingView?.removeFromSuperview()
        }

    }



    func makeLoadingView(withFrame frame: CGRect, loadingText text: String?) -> UIView? {
        let loadingView = UIView(frame: frame)
        loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        //activityIndicator.backgroundColor = UIColor(red:0.16, green:0.17, blue:0.21, alpha:1)
         
        activityIndicator.layer.cornerRadius = 6
        activityIndicator.center = loadingView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        activityIndicator.startAnimating()
        activityIndicator.tag = 100 // 100 for example

        loadingView.addSubview(activityIndicator)
        if !text!.isEmpty {
            let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
            let cpoint = CGPoint(x: activityIndicator.frame.origin.x + activityIndicator.frame.size.width / 2, y: activityIndicator.frame.origin.y + 80)
            lbl.center = cpoint
            lbl.textColor = UIColor.white
            lbl.textAlignment = .center
            lbl.text = text
            lbl.tag = 1234
            loadingView.addSubview(lbl)
        }
        return loadingView
    }
    
}
