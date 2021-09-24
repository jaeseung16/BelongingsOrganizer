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

class AddItemViewModel: NSObject, ObservableObject {
    private let persistenteContainer = PersistenceController.shared.container
    private var viewContext: NSManagedObjectContext {
        persistenteContainer.viewContext
    }
    
    @Published var showAlert = false
    
    var message = ""
    
    @Published var classificationResult: String = ""
    var imageData: Data? {
        didSet {
            updateClassifications()
        }
    }
    
    var kind: Kind?
    var brand: Brand?
    var seller: Seller?
    
    func saveBelonging(name: String, kind: Kind?, brand: Brand?, seller: Seller?, note: String, obtained: Date, buyPrice: Double?, quantity: Int64?, currency: String) -> Void {
        let created = Date()
        
        let newItem = Item(context: viewContext)
        newItem.created = created
        newItem.lastupd = created
        newItem.name = name
        newItem.note = note
        newItem.quantity = quantity ?? 0
        newItem.obtained = obtained
        newItem.buyPrice = buyPrice ?? 0.0
        newItem.currency = currency
        newItem.uuid = UUID()
        newItem.image = imageData
        
        if kind != nil {
            kind!.addToItems(newItem)
        }
        
        if brand != nil {
            brand!.addToItems(newItem)
        }
        
        if seller != nil {
            seller!.addToItems(newItem)
        }
        
        let originalMergePolicy = viewContext.mergePolicy
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        viewContext.mergePolicy = originalMergePolicy
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
}
