//
//  DBManager.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import CoreData
import Foundation
import UIKit

import UIKit
import CoreData

final class DBManager: Sendable {
    
    // Singleton Instance (This is implicitly lazy in Swift)
    static let shared = DBManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    // ❌ 'lazy var' removed because it causes concurrency errors in Swift 6.

    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NewsAppHarsh")
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ Unresolved Core Data Error: \(error), \(error.userInfo)")
            }
        }
        
        // Handling Duplicates
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // UI Updates: Automatically update UI when background changes happen
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // Main Thread Context (For Fetching Only)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Data (Background)
    
    func saveNewsCoreData(newData: [Article], completion: @escaping @Sendable () -> Void) {
        
        // Perform operations on background context to avoid Main Thread Freeze
        persistentContainer.performBackgroundTask { context in
            
            // 1. Order Logic
            let countRequest: NSFetchRequest<ArticleOfflineCore> = ArticleOfflineCore.fetchRequest()
            let currentCount = (try? context.count(for: countRequest)) ?? 0
            
            for (index, article) in newData.enumerated() {
                
                // 2. Duplicate Check
                let fetchRequest: NSFetchRequest<ArticleOfflineCore> = ArticleOfflineCore.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "articleUrl == %@", article.articleUrl ?? "")
                
                if let existing = try? context.fetch(fetchRequest), existing.isEmpty {
                    
                    let entity = ArticleOfflineCore(context: context)
                    
                    entity.author = article.author
                    entity.title = article.title
                    entity.content = article.content
                    entity.publishedAt = article.publishedAt
                    entity.descriptionText = article.descriptionText
                    entity.articleUrl = article.articleUrl
                    entity.imageUrl = article.imageUrl
                    
                    // Maintain Order
                    entity.order = Int64(currentCount + index)
                }
            }
            
            // Save & Notify
            try? context.save()
            print("✅ All Data SAVED Successfully (Background)")
            DispatchQueue.main.async { completion() }
        }
    }
    
    // MARK: - Fetch Data (Main Thread)
    
    func fetchCoreDataNews() -> [Article] {
        let fetchRequest: NSFetchRequest<ArticleOfflineCore> = ArticleOfflineCore.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.map { entity in
                Article(
                    author: entity.author,
                    title: entity.title,
                    descriptionText: entity.descriptionText,
                    articleUrl: entity.articleUrl,
                    imageUrl: entity.imageUrl,
                    publishedAt: entity.publishedAt,
                    content: entity.content
                )
            }
        } catch {
            print("❌ Fetch Error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Delete All Data (Background)
    
    func deleteAllData(completion: @escaping @Sendable () -> Void) {
        persistentContainer.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ArticleOfflineCore.fetchRequest()
            
            do {
                guard let results = try context.fetch(fetchRequest) as? [NSManagedObject] else { return }
                
                for object in results {
                    context.delete(object)
                }
                
                try context.save()
                print("✅ All Data DELETED Successfully (Background)")
                
                // Notify UI on Main Thread
                DispatchQueue.main.async { completion() }
                
            } catch {
                print("❌ Delete Error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion() }
            }
        }
    }
}
