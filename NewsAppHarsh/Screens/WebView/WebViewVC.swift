//
//  WebViewVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit
import WebKit

class WebViewVC: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var strNewsUrl = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Constant.shared.showLoader(true)
        webView.navigationDelegate = self
        
        if let url = URL(string: strNewsUrl) {
            let request = URLRequest(url: url)
            DispatchQueue.main.async{
                self.webView.load(request)
            }
            
        }
    }
    
    // WKNavigationDelegate method to handle page loading events
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //print("Page loaded successfully.")
        DispatchQueue.main.async {
            Constant.shared.showLoader(false)
        }
        // You can perform additional actions here when the page finishes loading.
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed to load page with error: \(error.localizedDescription)")
        // Handle error if needed
    }
    
    
}
