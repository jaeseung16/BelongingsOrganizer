//
//  BelongingsViewModel.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation
import Combine
import CoreData
import CoreML
import Vision
import CoreImage

class BelongingsViewModel: NSObject, ObservableObject {
    static let shared = BelongingsViewModel()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    static let dateFormatterWithDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
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
    
    var itemDTO = ItemDTO() {
        didSet {
            if itemDTO.id != nil, let existingEntity: Item = get(entity: .Item, id: itemDTO.id!) {
                existingEntity.name = itemDTO.name
                existingEntity.note = itemDTO.note
                existingEntity.quantity = itemDTO.quantity ?? 0
                existingEntity.buyPrice = itemDTO.buyPrice ?? 0.0
                existingEntity.sellPrice = itemDTO.sellPrice ?? 0.0
                existingEntity.currency = itemDTO.currency
                existingEntity.disposed = itemDTO.disposed
                existingEntity.image = itemDTO.image
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
    
    var kindDTO = KindDTO() {
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
    
    var brandDTO = BrandDTO() {
        didSet {
            if brandDTO.id != nil, let existingEntity: Brand = get(entity: .Brand, id: brandDTO.id!) {
                existingEntity.name = brandDTO.name
                existingEntity.url = brandDTO.url
                existingEntity.lastupd = Date()

                do {
                    try saveContext()
                } catch {
                    let nsError = error as NSError
                    print("While saving \(brandDTO) occured an unresolved error \(nsError), \(nsError.userInfo)")
                    message = "Cannot update name = \(String(describing: brandDTO.name)) and url = \(String(describing: brandDTO.url))"
                    showAlert.toggle()
                }
            }
        }
    }
    
    var sellerDTO = SellerDTO() {
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
        let predicate = NSPredicate(format: "uuid == %@", argumentArray: [id])
        
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
    
    // MARK: - Image Classification
    @Published var classificationResult: String = ""
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            /*
             Use the Swift class `MobileNet` Core ML generates from the model.
             To use a different Core ML classifier model, add it to the project
             and replace `MobileNet` with that model's generated Swift class.
             */
            let configuration = MLModelConfiguration()
            configuration.preferredMetalDevice = MTLCreateSystemDefaultDevice()
            
            let model = try VNCoreMLModel(for: MobileNet(configuration: configuration).model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                let classifications = request.results as! [VNClassificationObservation]
            
                if classifications.isEmpty {
                    self?.classificationResult = "Nothing recognized."
                } else {
                    // Display top classifications ranked by confidence in the UI.
                    let topClassifications = classifications.prefix(2)
                    let descriptions = topClassifications.map { classification in
                        // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                       return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                    }
                    
                    DispatchQueue.main.async {
                        self?.classificationResult = descriptions.joined(separator: " ")
                        print("classificationResult = \(self?.classificationResult)")
                    }
                }
            })
            request.imageCropAndScaleOption = .centerCrop
            print("request = \(request)")
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func updateClassifications(for data: Data?) {
        print("data = \(data)")
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = data, let ciImage = CIImage(data: data) else {
                return
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
}
