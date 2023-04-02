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

class AddItemViewModel {
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
    
    func save(item: Item, kind: [Kind], brand: Brand?, seller: Seller?, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        if !kind.isEmpty {
            kind.forEach { $0.addToItems(item) }
        }
        
        if brand != nil {
            brand!.addToItems(item)
        }
        
        if seller != nil {
            seller!.addToItems(item)
        }
        
        let originalMergePolicy = viewContext.mergePolicy
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistence.save(completionHandler: completionHandler)
        viewContext.mergePolicy = originalMergePolicy
    }
    
    func save(kind: Kind, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        persistence.save(completionHandler: completionHandler)
    }
    

    func save(brand: Brand, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        persistence.save(completionHandler: completionHandler)
    }
    
    func save(seller: Seller, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        persistence.save(completionHandler: completionHandler)
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
