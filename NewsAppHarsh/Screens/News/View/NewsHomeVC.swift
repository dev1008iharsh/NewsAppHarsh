//
//  NewsListHomeVC.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 31/01/24.
//

import UIKit

class NewsHomeVC: UIViewController {
    //MARK: -  @IBOutlet
    @IBOutlet weak var tblNewsList: UITableView!
    
    
    //MARK: -  Properties
    
    var totalResultsCount = 0
    var totalPage = 1
    var currentPage = 1
    
    private var news : NewsModel?
    private var viewModel = NewsViewModel()
    
    var marrArticles = [Articles]()
     
    var refreshControl = UIRefreshControl()
    
    //MARK: -  ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            Utility.shared.showLoader(true)
        }
        
        title = "Breaking News"
        
        configuration()
        
    }
    
}

extension NewsHomeVC{
    
    // this is work like viewDidLoad
    func configuration(){
        
        tblNewsList.register(UINib(nibName: "NewsTVC", bundle: nil), forCellReuseIdentifier: "NewsTVC")
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        initViewModel()
        
    }
    
    func initViewModel(){
        
        if NetworkReachability.shared.isNetworkAvailable() {
            print("Network is available")
            observeEvent()
            tblNewsList.addSubview(refreshControl)
            viewModel.fetchNewsApi(page: currentPage)
            
        } else {
            print("Network is not available")
            self.totalPage = 1
            self.offlineMessage()
            
            DispatchQueue.main.async {
                self.fetchOfflineDataFromCoreData()
                Utility.shared.showLoader(false)
            }
        }
    }
    
    func offlineMessage(){
        // Create a view
        
        let viewWidth: CGFloat = 270
        let myView = UIView(frame: CGRect(x: ((view.bounds.width - viewWidth) / 2), y: 150, width: viewWidth, height: 40))
        myView.layer.cornerRadius = 20
        myView.backgroundColor = .red
        
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: myView.bounds.width, height: myView.bounds.height))
        label.text = "Oops! No Internet Connection"
        label.textColor = .systemBackground
        label.textAlignment = .center
        
        myView.addSubview(label)
        self.view.addSubview(myView)
        
        
        UIView.animate(withDuration: 1.0, delay: 1.0, options: .curveEaseOut, animations: {
            myView.alpha = 0.0
        }, completion: { finished in
            
            myView.removeFromSuperview()
        })
        
        Utility.shared.heavyHapticFeedBack()
    }
    
    func fetchOfflineDataFromCoreData(){
        var arrNewsCoreData = [ArticleOfflineCore]()
        arrNewsCoreData = DBManager.shared.fetchCoreDataNews()
        //print("arrNewsCoreData",arrNewsCoreData)
        self.marrArticles.removeAll()
        for i in 0...arrNewsCoreData.count - 1{
            
            let arical = Articles(author: (arrNewsCoreData[i].author ?? ""), title: (arrNewsCoreData[i].title ?? ""), myDescription: (arrNewsCoreData[i].myDescription ?? ""), url: (arrNewsCoreData[i].url ?? ""), urlToImage: (arrNewsCoreData[i].urlToImage ?? ""), publishedAt: (arrNewsCoreData[i].publishedAt ?? ""), content: (arrNewsCoreData[i].content ?? ""))
            
            self.marrArticles.append(arical)
            
        }
        Utility.shared.heavyHapticFeedBack()
        self.tblNewsList.reloadData()
    }
    func calculateTotalPages(totalResultCount: Int, resultsPerPage: Int) -> Int {
        let totalPages = Int(ceil(Double(totalResultCount) / Double(resultsPerPage)))
        return totalPages
    }
    //MARK: -  API Response
    func observeEvent(){
        viewModel.eventHandler = { [weak self] event in
            guard let self else {return}
            
            switch event {
            case .loading:
                print("data loading")
                
            case .stopLoading:
                //print("loading finished")
                DispatchQueue.main.async {
                    Utility.shared.showLoader(false)
                    self.tblNewsList.stopLoading()
                }
                
            case .dataLoaded:
                //print(viewModel.newsDataModel)
                self.totalResultsCount = viewModel.newsDataModel?.totalResults ?? 1
                let totalPages = calculateTotalPages(totalResultCount: self.totalResultsCount, resultsPerPage: 20)
                
                self.totalPage = totalPages
                if currentPage == 1{
                    DBManager.shared.deleteAllData()
                }
            
                DispatchQueue.main.async {
                   
                    DBManager.shared.saveNewsCoreData(newData :  self.viewModel.articles) {
                        self.fetchOfflineDataFromCoreData()
                    }
                    
                }
            case .network(let error):
                print(error ?? "Error at ObserEvnt")
                
            }
            
        }
    }
    
    @objc func refreshData() {
        self.currentPage = 1
        self.marrArticles.removeAll()
        self.viewModel.fetchNewsApi(page: 1)
        self.tblNewsList.reloadData()
        self.refreshControl.endRefreshing()
        Utility.shared.heavyHapticFeedBack()
    }
    
}

//MARK: -  UITableViewDelegate, UITableViewDataSource
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
        
        if NetworkReachability.shared.isNetworkAvailable() {
            let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
            
            if let url = marrArticles[sender.tag].url{
                
                Utility.shared.lightHapticFeedBack()
                
                nextVC.strNewsUrl = url
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        } else {
            Utility.shared.heavyHapticFeedBack()
            Utility.shared.showAlertHandler(title: "Oops! It seems like you're offline", message: "Please check your internet connection and try again later.", view: self) { alert in
                self.dismiss(animated: true)
            }
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0001) {
            if tableView.visibleCells.contains(cell) {
                if (indexPath.row == self.marrArticles.count - 1) && (self.totalPage > self.currentPage){
                    
                    self.currentPage = self.currentPage + 1
                    self.viewModel.fetchNewsApi(page: self.currentPage)
                    
                    tableView.addLoading(indexPath)
                }
            }
        }
        
        
    }
    
}


