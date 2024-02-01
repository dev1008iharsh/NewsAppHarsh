//
//  NewsListHomeVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit

class NewsHomeVC: UIViewController {
    
    @IBOutlet weak var tblNewsList: UITableView!
    
    
    //MARK: -  Properties
    
    private var news : NewsModel?
    private var viewModel = NewsViewModel()
    
    var marrArticles = [Articles]()
    var arrNewsCoreData = [ArticleOfflineCore]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            Constant.shared.showLoader(true)
        }
        
        title = "Breaking News"
        
        configuration()
         
    }
    
}

extension NewsHomeVC{
    
    // this is work like viewDidLoad
    func configuration(){
        tblNewsList.register(UINib(nibName: "NewsTVC", bundle: nil), forCellReuseIdentifier: "NewsTVC")
        initViewModel()
        observeEvent()
    }
    
    func initViewModel(){
        
        
        if NetworkReachability.shared.isNetworkAvailable() {
            print("Network is available")
            viewModel.fetchNewsApi()
        } else {
            print("Network is not available")
            fetchOfflineDataFromCoreData()
            DispatchQueue.main.async {
                Constant.shared.showLoader(false)
            }
            
            
        }
    }
    func fetchOfflineDataFromCoreData(){
        self.arrNewsCoreData = DBManager.shared.fetchCoreDataNews()
        //print("arrNewsCoreData",self.arrNewsCoreData)
        
        for i in 0...self.arrNewsCoreData.count - 1{
            
            let arical = Articles(author: (self.arrNewsCoreData[i].author ?? ""), title: (self.arrNewsCoreData[i].title ?? ""), myDescription: (self.arrNewsCoreData[i].myDescription ?? ""), url: (self.arrNewsCoreData[i].url ?? ""), urlToImage: (self.arrNewsCoreData[i].urlToImage ?? ""), publishedAt: (self.arrNewsCoreData[i].publishedAt ?? ""), content: (self.arrNewsCoreData[i].content ?? ""))
            
            self.marrArticles.append(arical)
            
        }
        
        self.tblNewsList.reloadData()
    }
    
    func observeEvent(){
        viewModel.eventHandler = { [weak self] event in
            guard let self else {return}
            
            switch event {
            case .loading:
                print("data loading")
            case .stopLoading:
                print("loading finished")
                DispatchQueue.main.async {
                    Constant.shared.showLoader(false)
                }
                
            case .dataLoaded:
                //print(viewModel.newsDataModel)
                
                if let articles = viewModel.newsDataModel?.articles{
                    //self.marrArticles = articles
                    
                    DispatchQueue.main.async {
                        DBManager.shared.deleteAllData()
                        
                        DBManager.shared.saveNewsCoreData(articles)
                        
                        self.fetchOfflineDataFromCoreData()
                        
                        print("***dataLoaded marrArticles",self.marrArticles)
                        
                    }
                    
                }
            case .network(let error):
                print(error ?? "Error at ObserEvnt")
                
            }
            
        }
    }
}
 
extension NewsHomeVC : UITableViewDataSource,UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return marrArticles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTVC", for: indexPath) as? NewsTVC else {
            return UITableViewCell()
        }
        
        cell.article = marrArticles[indexPath.row]
        
        cell.btnWeb.addTarget(self, action: #selector(btnWebTapped(sender:)), for:.touchUpInside)
        cell.btnWeb.tag = indexPath.row
        
        return cell
        
    }
    
    @objc func btnWebTapped(sender: UIButton) {
        
        // we can also use closure for navigation on click tap - here i use another method
        
        let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
        
        if let url = marrArticles[sender.tag].url{
            nextVC.strNewsUrl = url
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "NewsDetailsVC") as! NewsDetailsVC
        
        nextVC.article = marrArticles[indexPath.row]
        
        self.navigationController?.pushViewController(nextVC, animated: true)
        
    }
      
}


