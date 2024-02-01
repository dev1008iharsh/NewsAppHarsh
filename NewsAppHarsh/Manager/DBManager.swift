//
//  DBManager.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import CoreData
import UIKit

class DBManager{
    static let shared = DBManager()
    private init(){}
    private var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func saveNewsCoreData(_ newsModel: [Articles]) {
        
        for index in 0..<newsModel.count {
            let articalEntity = ArticleOfflineCore(context: context) // navo user create kare
            articalEntity.author = newsModel[index].author
            articalEntity.title = newsModel[index].title
            articalEntity.myDescription = newsModel[index].myDescription
            articalEntity.url = newsModel[index].url
            articalEntity.urlToImage = newsModel[index].urlToImage
            articalEntity.publishedAt = newsModel[index].publishedAt
            articalEntity.content = newsModel[index].content
        }
        
        saveContext()
    }
    
    
    func fetchCoreDataNews() -> [ArticleOfflineCore] {
        var users: [ArticleOfflineCore] = []
        
        do {
            users = try context.fetch(ArticleOfflineCore.fetchRequest())
            print("*** FETCHED CoreData Successfully")
        }catch {
            print("*** Fetch CoreDatauser error", error)
        }
        
        return users
    }
    
    func saveContext() {
        do {
            try context.save() // aa karya vafar database ma save na thay
            print("*** SAVED CoreData Successfully")
        }catch {
            print("*** User CoreData saving error", error)
        }
    }
    
    func deleteAllData() {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ArticleOfflineCore")
        
        do {
            let entities = try context.fetch(fetchRequest) as! [NSManagedObject]
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            //print("*** DELETED CoreDataSuccessfully")
        } catch let error {
            print("Error CoreData deleting all data: \(error)")
        }
    }
    
    
}


