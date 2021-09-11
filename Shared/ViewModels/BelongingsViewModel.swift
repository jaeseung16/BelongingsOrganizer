//
//  BelongingsViewModel.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation
import Combine
import CoreData

class BelongingsViewModel: NSObject, ObservableObject {
    static let shared = BelongingsViewModel()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    private let persistenteContainer = PersistenceController.shared.container
    
    private var subscriptions: Set<AnyCancellable> = []
    
    @Published var showAlert = false
    
    var message = ""
    
    override init() {
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
    }
    
    var kindDTO = KindDTO(id: nil, name: nil) {
        didSet {
            if kindDTO.id != nil, let existingEntity: Kind = get(entity: .Kind, id: kindDTO.id!) {
                existingEntity.name = kindDTO.name
                existingEntity.lastupd = Date()

                do {
                    try saveContext()
                } catch {
                    let nsError = error as NSError
                    print("While saving \(kindDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    message = "Cannot update name = \(String(describing: kindDTO.name))"
                    showAlert.toggle()
                }
            }
        }
    }
    
    var manufacturerDTO = ManufacturerDTO(id: nil, name: nil, url: nil) {
        didSet {
            if manufacturerDTO.id != nil, let existingEntity: Manufacturer = get(entity: .Manufacturer, id: manufacturerDTO.id!) {
                existingEntity.name = manufacturerDTO.name
                existingEntity.url = manufacturerDTO.url
                existingEntity.lastupd = Date()

                do {
                    try saveContext()
                } catch {
                    let nsError = error as NSError
                    print("While saving \(manufacturerDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    message = "Cannot update name = \(String(describing: manufacturerDTO.name)) and url = \(String(describing: manufacturerDTO.url))"
                    showAlert.toggle()
                }
            }
        }
    }
    
    var sellerDTO = SellerDTO(id: nil, name: nil, url: nil) {
        didSet {
            if sellerDTO.id != nil, let existingEntity: Seller = get(entity: .Seller, id: sellerDTO.id!) {
                existingEntity.name = sellerDTO.name
                existingEntity.url = sellerDTO.url
                existingEntity.lastupd = Date()

                do {
                    try saveContext()
                } catch {
                    let nsError = error as NSError
                    print("While saving \(sellerDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    message = "Cannot update name = \(String(describing: sellerDTO.name)) and url = \(String(describing: sellerDTO.url))"
                    showAlert.toggle()
                }
            }
        }
    }
    
    func get<Entity: NSFetchRequestResult>(entity: Entities, id: UUID) -> Entity? {
        let predicate = NSPredicate(format: "id == %@", argumentArray: [id])
        
        let fetchRequest = NSFetchRequest<Entity>(entityName: entity.rawValue)
        fetchRequest.predicate = predicate
        
        var fetchedLinks = [Entity]()
        do {
            fetchedLinks = try persistenteContainer.viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch \(entity) with uuid = \(id): \(error)")
        }
        
        return fetchedLinks.isEmpty ? nil : fetchedLinks[0]
    }
    
    private func saveContext() throws -> Void {
        persistenteContainer.viewContext.transactionAuthor = "App"
        try persistenteContainer.viewContext.save()
        persistenteContainer.viewContext.transactionAuthor = nil
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        historyRequestQueue.async {
            let backgroundContext = self.persistenteContainer.newBackgroundContext()
            backgroundContext.performAndWait {
                do {
                    let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
                    
                    if let historyResult = try backgroundContext.execute(fetchHistoryRequest) as? NSPersistentHistoryResult,
                       let history = historyResult.result as? [NSPersistentHistoryTransaction] {
                        for transaction in history.reversed() {
                            self.persistenteContainer.viewContext.perform {
                                if let userInfo = transaction.objectIDNotification().userInfo {
                                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo,
                                                                        into: [self.persistenteContainer.viewContext])
                                }
                            }
                        }
                        
                        self.lastToken = history.last?.token
                    }
                } catch {
                    print("Could not convert history result to transactions after lastToken = \(String(describing: self.lastToken)): \(error)")
                }
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
                print("###\(#function): \(message): \(error)")
            }
        }
    }
    
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("LinkCollector",isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL"
                print("###\(#function): \(message): \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
}
