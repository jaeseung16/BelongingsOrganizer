//
//  Persistence.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import CoreData
import os

struct PersistenceController {
    static let shared = PersistenceController()
    static let logger = Logger()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let kindName = ["Book", "TV", "Phone", "Car", "Box", "Watch", "Water", "Glasses", "Bag" , "Shoes"]
        let itemName = ["Reinforcement Learning", "FIJI", "iPhone 12 mini"]
        
        for index in 0..<kindName.count {
            let newKind = Kind(context: viewContext)
            newKind.created = Date()
            newKind.name = kindName[index]
        }
        
        for index in 0..<itemName.count {
            let newItem = Item(context: viewContext)
            newItem.created = Date()
            newItem.name = itemName[index]
        }
        
        PersistenceController.save(viewContext: viewContext) { error in
            let nsError = error as NSError
            PersistenceController.logger.error("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Belongings")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.resonance.jlee.Belongings")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                PersistenceController.logger.error("Could not load persistent store: \(storeDescription), \(error), \(error.userInfo)")
            }
        })
        
        print("persistentStores = \(container.persistentStoreCoordinator.persistentStores)")
        
        container.viewContext.name = "Belongings"
        purgeHistory()
    }
    
    private func purgeHistory() {
        let sevenDaysAgo = Date(timeIntervalSinceNow: TimeInterval(exactly: -604_800)!)
        let purgeHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)

        do {
            try container.newBackgroundContext().execute(purgeHistoryRequest)
        } catch {
            if let error = error as NSError? {
                PersistenceController.logger.error("Could not purge history: \(error), \(error.userInfo)")
            }
        }
    }
    
    static func save(viewContext: NSManagedObjectContext, completionHandler: (Error) -> Void) {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                if let error = error as NSError? {
                    PersistenceController.logger.error("Could not save: \(error), \(error.userInfo)")
                }
                completionHandler(error)
            }
        }
    }
}
