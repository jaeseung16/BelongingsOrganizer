//
//  BelongingsViewModel.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation
import Combine
import CoreData
import SDWebImageWebPCoder
import os
import Persistence

class BelongingsViewModel: NSObject, ObservableObject {
    let logger = Logger()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dateFormatterWithDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var persistence: Persistence
    private var persistenceContainer: NSPersistentCloudKitContainer {
        persistence.cloudContainer!
    }
    
    private var subscriptions: Set<AnyCancellable> = []
    
    @Published var changedPeristentContext = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    @Published var showAlert = false
    @Published var stringToSearch = ""
    @Published var toggle = false
    
    var message = ""
    
    let addItemViewModel: AddItemViewModel
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.addItemViewModel = AddItemViewModel(persistence: persistence)
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)
        
        self.persistence.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var items: [Item] {
        fetch(NSFetchRequest<Item>(entityName: "Item"))
    }
    
    var kinds: [Kind] {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Kind>(entityName: "Kind")
        fetchRequest.sortDescriptors = sortDescriptors
        return fetch(fetchRequest)
    }
    
    var brands: [Brand] {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Brand>(entityName: "Brand")
        fetchRequest.sortDescriptors = sortDescriptors
        return fetch(fetchRequest)
    }
    
    var sellers: [Seller] {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Seller>(entityName: "Seller")
        fetchRequest.sortDescriptors = sortDescriptors
        return fetch(fetchRequest)
    }
    
    private func fetch<Element>(_ fetchRequest: NSFetchRequest<Element>) -> [Element] {
        var fetchedEntities = [Element]()
        do {
            fetchedEntities = try persistenceContainer.viewContext.fetch(fetchRequest)
        } catch {
            self.logger.error("Failed to fetch: \(error.localizedDescription)")
        }
        return fetchedEntities
    }
    
    var itemDTO = ItemDTO() {
        didSet {
            if itemDTO.id != nil, let existingEntity: Item = get(entity: .Item, id: itemDTO.id!) {
                existingEntity.name = itemDTO.name
                existingEntity.note = itemDTO.note
                existingEntity.quantity = itemDTO.quantity ?? 0
                existingEntity.buyPrice = itemDTO.buyPrice ?? 0.0
                existingEntity.sellPrice = itemDTO.sellPrice ?? 0.0
                existingEntity.buyCurrency = itemDTO.buyCurrency
                existingEntity.sellCurrency = itemDTO.sellCurrency
                existingEntity.disposed = itemDTO.disposed
                existingEntity.image = itemDTO.image
                existingEntity.lastupd = Date()

                saveContext() { [self] error in
                    let nsError = error as NSError
                    self.logger.error("While saving \(self.itemDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    self.message = "Cannot update name = \(String(describing: itemDTO.name))"
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    var kindDTO = KindDTO() {
        didSet {
            if kindDTO.id != nil, let existingEntity: Kind = get(entity: .Kind, id: kindDTO.id!) {
                existingEntity.name = kindDTO.name?.trimmingCharacters(in: .whitespaces)
                existingEntity.lastupd = Date()

                saveContext() { error in
                    let nsError = error as NSError
                    self.logger.error("While saving \(self.kindDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    self.message = "Cannot update name = \(String(describing: self.kindDTO.name))"
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    var brandDTO = BrandDTO() {
        didSet {
            if brandDTO.id != nil, let existingEntity: Brand = get(entity: .Brand, id: brandDTO.id!) {
                existingEntity.name = brandDTO.name?.trimmingCharacters(in: .whitespaces)
                existingEntity.url = brandDTO.url
                existingEntity.lastupd = Date()

                saveContext() { error in
                    let nsError = error as NSError
                    self.logger.error("While saving \(self.brandDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    self.message = "Cannot update name = \(String(describing: self.brandDTO.name)) and url = \(String(describing: self.brandDTO.url))"
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    var sellerDTO = SellerDTO() {
        didSet {
            if sellerDTO.id != nil, let existingEntity: Seller = get(entity: .Seller, id: sellerDTO.id!) {
                existingEntity.name = sellerDTO.name?.trimmingCharacters(in: .whitespaces)
                existingEntity.url = sellerDTO.url
                existingEntity.lastupd = Date()

                saveContext() { error in
                    let nsError = error as NSError
                    self.logger.error("While saving \(self.sellerDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    self.message = "Cannot update name = \(String(describing: self.sellerDTO.name)) and url = \(String(describing: self.sellerDTO.url))"
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    func get<Entity: NSFetchRequestResult>(entity: Entities, id: UUID) -> Entity? {
        let predicate = NSPredicate(format: "uuid == %@", argumentArray: [id])
        
        let fetchRequest = NSFetchRequest<Entity>(entityName: entity.rawValue)
        fetchRequest.predicate = predicate
        
        var fetchedLinks = [Entity]()
        do {
            fetchedLinks = try persistenceContainer.viewContext.fetch(fetchRequest)
        } catch {
            logger.error("Failed to fetch \(entity.rawValue) with uuid = \(id): \(error.localizedDescription)")
            showAlert.toggle()
        }
        
        return fetchedLinks.isEmpty ? nil : fetchedLinks[0]
    }
    
    func delete(_ objects: [NSManagedObject], completionHandler: @escaping (Error) -> Void) -> Void {
        objects.forEach(persistenceContainer.viewContext.delete)
        saveContext(completionHandler: completionHandler)
    }
    
    private func saveContext(completionHandler: @escaping (Error) -> Void) -> Void {
        persistenceContainer.viewContext.transactionAuthor = "App"
        persistence.save { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self.toggle.toggle()
                }
            case .failure(let error):
                self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                self.logger.log("Error while saving data: \(Thread.callStackSymbols, privacy: .public)")
                print("Error while saving data: \(Thread.callStackSymbols)")
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                    completionHandler(error)
                }
            }
        }
        
        persistenceContainer.viewContext.transactionAuthor = nil
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.toggle.toggle()
                }
            case .failure(let error):
                self.logger.log("Error while updating history: \(error.localizedDescription, privacy: .public) \(Thread.callStackSymbols, privacy: .public)")
            }
        }
    }
    
    private var lastToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastToken,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
                return
            }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                let message = "Could not write token data"
                logger.error("###\(#function): \(message): \(error.localizedDescription)")
            }
        }
    }
    
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("BelongingsOrganizer", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL"
                logger.error("###\(#function): \(message): \(error.localizedDescription)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

}
