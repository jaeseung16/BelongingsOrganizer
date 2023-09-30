//
//  AddItemViewModel.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/21.
//

import Foundation
import Combine
import CoreData
import CoreML
import Vision
import CoreImage
import os
import Persistence

class PersistenceHelper {
    private static let logger = Logger()
    
    private let persistence: Persistence
    var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    var classificationResult: String = ""
    var imageData: Data?
    
    func reset() {
        imageData = nil
    }
    
    func perform<Element>(_ fetchRequest: NSFetchRequest<Element>) -> [Element] {
        var fetchedEntities = [Element]()
        do {
            fetchedEntities = try viewContext.fetch(fetchRequest)
        } catch {
            PersistenceHelper.logger.error("Failed to fetch with fetchRequest=\(fetchRequest, privacy: .public): error=\(error.localizedDescription, privacy: .public)")
        }
        return fetchedEntities
    }
    
    func getFetchRequest<Entity: NSFetchRequestResult>(for type: Entity.Type, entityName: String, sortDescriptors: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) -> NSFetchRequest<Entity> {
        let fetchRequest = NSFetchRequest<Entity>(entityName: entityName)
        if !sortDescriptors.isEmpty {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        return fetchRequest
    }
    
    func get(entity: Entities, id: UUID) -> NSManagedObject? {
        let predicate = NSPredicate(format: "uuid == %@", argumentArray: [id])
        let fetchRequest = getFetchRequest(for: entity.type, entityName: entity.rawValue, sortDescriptors: [], predicate: predicate)
        let fetchedEntities = perform(fetchRequest)
        return fetchedEntities.isEmpty ? nil : fetchedEntities[0]
    }
    
    // MARK: - Create
    public func save(_ dto: ItemDTO, kind: [Kind], brand: Brand?, seller: Seller?, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        let created = Date()
        
        let newItem = Item(context: viewContext)
        newItem.created = created
        newItem.lastupd = created
        newItem.name = dto.name
        newItem.note = dto.note
        newItem.quantity = dto.quantity ?? 0
        newItem.obtained = dto.obtained
        newItem.buyPrice = dto.buyPrice ?? 0.0
        newItem.buyCurrency = dto.buyCurrency
        newItem.uuid = dto.id
        newItem.image = dto.image
       
        if !kind.isEmpty {
            kind.forEach { $0.addToItems(newItem) }
        }
        
        if let brand {
            brand.addToItems(newItem)
        }
        
        if let seller {
            seller.addToItems(newItem)
        }
        
        saveContext(completionHandler: completionHandler)
    }
    
    public func save(_ dto: KindDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        let created = Date()
        
        let newKind = Kind(context: viewContext)
        newKind.created = created
        newKind.lastupd = created
        newKind.name = dto.name
        newKind.uuid = dto.id
        
        saveContext(completionHandler: completionHandler)
    }
    
    public func save(_ dto: BrandDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        let created = Date()
        
        let newBrand = Brand(context: viewContext)
        newBrand.created = created
        newBrand.lastupd = created
        newBrand.name = dto.name
        newBrand.url = dto.url
        newBrand.uuid = dto.id

        saveContext(completionHandler: completionHandler)
    }
    
    public func save(_ dto: SellerDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        let created = Date()
        
        let newSeller = Seller(context: viewContext)
        newSeller.created = created
        newSeller.lastupd = created
        newSeller.name = dto.name
        newSeller.url = dto.url
        newSeller.uuid = dto.id

        saveContext(completionHandler: completionHandler)
    }
    
    // MARK: - Update
    public func update(_ item: Item, to dto: ItemDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        item.name = dto.name
        item.note = dto.note
        item.quantity = dto.quantity ?? 0
        item.buyPrice = dto.buyPrice ?? 0.0
        item.sellPrice = dto.sellPrice ?? 0.0
        item.buyCurrency = dto.buyCurrency
        item.sellCurrency = dto.sellCurrency
        item.obtained = dto.obtained
        item.disposed = dto.disposed
        item.image = dto.image
        item.lastupd = Date()
        
        saveContext(completionHandler: completionHandler)
    }
    
    public func update(_ kind: Kind, to dto: KindDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        kind.name = dto.name?.trimmingCharacters(in: .whitespaces)
        kind.lastupd = Date()
        
        saveContext(completionHandler: completionHandler)
    }
    
    public func update(_ brand: Brand, to dto: BrandDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        brand.name = dto.name?.trimmingCharacters(in: .whitespaces)
        brand.url = dto.url
        brand.lastupd = Date()
        
        saveContext(completionHandler: completionHandler)
    }
    
    public func update(_ seller: Seller, to dto: SellerDTO, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        seller.name = dto.name?.trimmingCharacters(in: .whitespaces)
        seller.url = dto.url
        seller.lastupd = Date()
        
        saveContext(completionHandler: completionHandler)
    }
    
    // MARK: - Image Classification
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
                        print("classificationResult = \(String(describing: self?.classificationResult))")
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
    
    func updateClassifications() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = self.imageData, let ciImage = CIImage(data: data) else {
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
    
    private func saveContext(completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        viewContext.transactionAuthor = "App"
        let originalMergePolicy = viewContext.mergePolicy
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistence.save(completionHandler: completionHandler)
        viewContext.mergePolicy = originalMergePolicy
        viewContext.transactionAuthor = nil
    }
    
    func delete(_ objects: [NSManagedObject], completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        objects.forEach(viewContext.delete)
        saveContext(completionHandler: completionHandler)
    }
    
    func save(completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        saveContext(completionHandler: completionHandler)
    }
    
}
