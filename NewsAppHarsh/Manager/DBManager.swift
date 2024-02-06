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
    
    func saveNewsCoreData(newData: [Articles], completion: @escaping () -> Void) {
        // Fetch existing data
        var existingData = fetchCoreDataNews()
        //print("existingData",existingData)
        
        // Determine the starting index for the order
        let startingIndex = existingData.count
        
        // Append new data to existing data
        for (index, article) in newData.enumerated() {
            let articalEntity = ArticleOfflineCore(context: context) // Create new instance
            articalEntity.author = article.author
            articalEntity.title = article.title
            articalEntity.myDescription = article.myDescription
            articalEntity.url = article.url
            articalEntity.urlToImage = article.urlToImage
            articalEntity.publishedAt = article.publishedAt
            articalEntity.content = article.content
            articalEntity.order = Int64(startingIndex + index) // Set the order
            
            existingData.append(articalEntity) // Append to existing data
        }
        
        // Save the updated data
        saveContext()
        
        // Call completion handler
        completion()
    }
    
    func fetchCoreDataNews() -> [ArticleOfflineCore] {
        let fetchRequest: NSFetchRequest<ArticleOfflineCore> = ArticleOfflineCore.fetchRequest()
        
        // Sort descriptor to fetch entities based on the order attribute
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let existingData = try context.fetch(fetchRequest)
            return existingData
        } catch {
            // Handle error here
            print("Error fetching existing data: \(error.localizedDescription)")
            return []
        }
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


