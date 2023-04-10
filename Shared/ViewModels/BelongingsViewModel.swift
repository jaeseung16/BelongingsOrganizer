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
import SwiftUI

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
    
    @Published var updated = false
    
    var message = ""
    
    let addItemViewModel: AddItemViewModel
    let imagePaster = ImagePaster.shared
    
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
        
        fetchEntities()
    }
    
    private func fetchEntities() -> Void {
        fetchItems()
        fetchKinds()
        fetchBrands()
        fetchSellers()
        logger.log("items.count=\(self.items.count)")
        logger.log("kinds.count=\(self.kinds.count)")
        logger.log("brands.count=\(self.brands.count)")
        logger.log("sellers.count=\(self.sellers.count)")
    }
    
    @Published var items = [ItemDTO]()
    
    func fetchItems() -> Void {
        items = fetch(NSFetchRequest<Item>(entityName: "Item"))
            .map {
                var kinds: Set<KindDTO>?
                if let kindSet = $0.kind as? Set<Kind> {
                    kinds = Set(kindSet.map {
                        KindDTO(id: $0.uuid, name: $0.name, created: $0.created, lastupd: $0.lastupd)
                    })
                }
                
                var brands: Set<BrandDTO>?
                if let brandSet = $0.brand as? Set<Brand> {
                    brands = Set(brandSet.map {
                        BrandDTO(id: $0.uuid, name: $0.name, url: $0.url, created: $0.created, lastupd: $0.lastupd)
                    })
                }
                
                var sellers: Set<SellerDTO>?
                if let sellerSet = $0.seller as? Set<Seller> {
                    sellers = Set(sellerSet.map {
                        SellerDTO(id: $0.uuid, name: $0.name, url: $0.url, created: $0.created, lastupd: $0.lastupd)
                    })
                }
                
                return ItemDTO(id: $0.uuid,
                               name: $0.name,
                               note: $0.note,
                               quantity: $0.quantity,
                               buyPrice: $0.buyPrice,
                               sellPrice: $0.sellPrice,
                               buyCurrency: $0.buyCurrency,
                               sellCurrency: $0.sellCurrency,
                               obtained: $0.obtained,
                               disposed: $0.disposed,
                               image: $0.image,
                               created: $0.created,
                               lastupd: $0.lastupd,
                               kinds: kinds,
                               brands: brands,
                               sellers: sellers)
            }
    }
    
    @Published var kinds = [KindDTO]()
    
    func fetchKinds() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Kind>(entityName: "Kind")
        fetchRequest.sortDescriptors = sortDescriptors
        kinds = fetch(fetchRequest).map { KindDTO(id: $0.uuid, name: $0.name, created: $0.created, lastupd: $0.lastupd) }
    }
    
    @Published var brands = [BrandDTO]()
    
    func fetchBrands() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Brand>(entityName: "Brand")
        fetchRequest.sortDescriptors = sortDescriptors
        brands = fetch(fetchRequest).map { BrandDTO(id: $0.uuid, name: $0.name, url: $0.url, created: $0.created, lastupd: $0.lastupd) }
    }
    
    @Published var sellers = [SellerDTO]()
    
    func fetchSellers() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Seller>(entityName: "Seller")
        fetchRequest.sortDescriptors = sortDescriptors
        sellers = fetch(fetchRequest).map { SellerDTO(id: $0.uuid, name: $0.name, url: $0.url, created: $0.created, lastupd: $0.lastupd) }
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
                
                saveContext() { error in
                    guard let error = error else {
                        return
                    }
                    self.logger.error("While saving \(self.itemDTO) occured an unresolved error \(error.localizedDescription, privacy: .public)")
                    self.message = "Cannot update name = \(String(describing: self.itemDTO.name))"
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
                    guard let error = error else {
                        return
                    }
                    self.logger.error("While saving \(self.kindDTO) occured an unresolved error \(error.localizedDescription, privacy: .public)")
                    self.message = "Cannot update name = \(String(describing: self.kindDTO.name))"
                    DispatchQueue.main.async {
                        self.showAlert.toggle()
                    }
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
                    guard let error = error else {
                        return
                    }
                    self.logger.error("While saving \(self.brandDTO) occured an unresolved error \(error.localizedDescription, privacy: .public)")
                    self.message = "Cannot update name = \(String(describing: self.brandDTO.name)) and url = \(String(describing: self.brandDTO.url))"
                    DispatchQueue.main.async {
                        self.showAlert.toggle()
                    }
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
                    guard let error = error else {
                        return
                    }
                    self.logger.error("While saving \(self.sellerDTO) occured an unresolved error \(error.localizedDescription, privacy: .public)")
                    self.message = "Cannot update name = \(String(describing: self.sellerDTO.name)) and url = \(String(describing: self.sellerDTO.url))"
                    DispatchQueue.main.async {
                        self.showAlert.toggle()
                    }
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
    
    func delete(_ objects: [NSManagedObject], completionHandler: @escaping (Error?) -> Void) -> Void {
        objects.forEach(persistenceContainer.viewContext.delete)
        saveContext(completionHandler: completionHandler)
    }
    
    private func saveContext(completionHandler: @escaping (Error?) -> Void) -> Void {
        persistenceContainer.viewContext.transactionAuthor = "App"
        persistence.save { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self.updated.toggle()
                    completionHandler(nil)
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
                    self.updated.toggle()
                }
            case .failure(let error):
                self.logger.log("Error while updating history: \(error.localizedDescription, privacy: .public) \(Thread.callStackSymbols, privacy: .public)")
            }
        }
    }
    
    // MARK: -
    public func checkIfStringToSearchContainedIn(_ input: String?) -> Bool {
        if stringToSearch == "" {
            return true
        } else if let input = input {
            return input.lowercased().contains(stringToSearch.lowercased())
        } else {
            return false
        }
    }
    
    // MARK: - Stats
    private let maxCountForStats = 10
    private let others = "others"
    
    public func itemCountsByKind(from start: Date, to end: Date) -> [KindStats] {
        var result = [KindStats]()
        let itemsObtainedBetweenStartAndEnd = itemsObtainedBetween(from: start, to: end)
        
        var itemsObtainedByKind = [String: Int]()
        for item in itemsObtainedBetweenStartAndEnd {
            if let kindSet = item.kind {
                for kind in kindSet {
                    if let kind = kind as? Kind, let name = kind.name {
                        if let itemcount = itemsObtainedByKind[name] {
                            itemsObtainedByKind[name] = itemcount + 1
                        } else {
                            itemsObtainedByKind[name] = 1
                        }
                    }
                }
            }
        }
        
        let itemCountsByKind = itemsObtainedByKind.map { (name, itemCount) in
            return KindStats(name: name, itemCount: itemCount)
        }.sorted(by: { $0.itemCount > $1.itemCount })
        
        if (itemCountsByKind.count > maxCountForStats) {
            result.append(contentsOf: itemCountsByKind[..<maxCountForStats])
            result.append(KindStats(name: others, itemCount: itemCountsByKind[maxCountForStats...].reduce(0, { $0 + $1.itemCount })))
        } else {
            result.append(contentsOf: itemCountsByKind)
        }
        
        return result
        
    }
    
    private func itemsObtainedBetween(from start: Date, to end: Date) -> [Item] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        return fetch(NSFetchRequest<Item>(entityName: "Item")).filter { item in
            if item.kind != nil, let obtained = item.obtained {
                return calendar.compare(startDate, to: obtained, toGranularity: .hour) != .orderedDescending && calendar.compare(obtained, to: endDate, toGranularity: .hour) != .orderedDescending
            } else {
                return false
            }
        }
    }
    
    public func itemCountByBrand(from start: Date, to end: Date) -> [BrandStats] {
        var result = [BrandStats]()
        let itemsObtainedBetweenStartAndEnd = itemsObtainedBetween(from: start, to: end)
        
        var itemsObtainedByBrand = [String: Int]()
        for item in itemsObtainedBetweenStartAndEnd {
            if let brandSet = item.brand {
                for brand in brandSet {
                    if let brand = brand as? Brand, let name = brand.name {
                        if let itemcount = itemsObtainedByBrand[name] {
                            itemsObtainedByBrand[name] = itemcount + 1
                        } else {
                            itemsObtainedByBrand[name] = 1
                        }
                    }
                }
            }
        }
        
        let itemCountsByBrand = itemsObtainedByBrand.map { (name, itemCount) in
            return BrandStats(name: name, itemCount: itemCount)
        }.sorted(by: { $0.itemCount > $1.itemCount })
        
        if (itemCountsByBrand.count > maxCountForStats) {
            result.append(contentsOf: itemCountsByBrand[..<maxCountForStats])
            result.append(BrandStats(name: others, itemCount: itemCountsByBrand[maxCountForStats...].reduce(0, { $0 + $1.itemCount })))
        } else {
            result.append(contentsOf: itemCountsByBrand)
        }
        
        return result
        
    }
    
    public func itemCountBySeller(from start: Date, to end: Date) -> [SellerStats] {
        var result = [SellerStats]()
        let itemsObtainedBetweenStartAndEnd = itemsObtainedBetween(from: start, to: end)
        
        var itemsObtainedBySeller = [String: Int]()
        for item in itemsObtainedBetweenStartAndEnd {
            if let brandSet = item.brand {
                for brand in brandSet {
                    if let brand = brand as? Brand, let name = brand.name {
                        if let itemcount = itemsObtainedBySeller[name] {
                            itemsObtainedBySeller[name] = itemcount + 1
                        } else {
                            itemsObtainedBySeller[name] = 1
                        }
                    }
                }
            }
        }
        
        let itemCountsBySeller =  itemsObtainedBySeller.map { (name, itemCount) in
            return SellerStats(name: name, itemCount: itemCount)
        }.sorted(by: { $0.itemCount > $1.itemCount })
        
        if (itemCountsBySeller.count > maxCountForStats) {
            result.append(contentsOf: itemCountsBySeller[..<maxCountForStats])
            result.append(SellerStats(name: others, itemCount: itemCountsBySeller[maxCountForStats...].reduce(0, { $0 + $1.itemCount })))
        } else {
            result.append(contentsOf: itemCountsBySeller)
        }
        
        return result
        
    }
    
    // MARK: - AddItemViewModel
    public var imageData: Data? {
        return addItemViewModel.imageData
    }
    
    public func updateImage(_ imageData: Data?) {
        addItemViewModel.imageData = imageData
    }
    
    public func saveBelonging(name: String, kind: [KindDTO], brand: BrandDTO?, seller: SellerDTO?, note: String, obtained: Date, buyPrice: Double?, quantity: Int64?, buyCurrency: String) -> Void {
        let created = Date()
        
        let newItem = Item(context: addItemViewModel.viewContext)
        newItem.created = created
        newItem.lastupd = created
        newItem.name = name
        newItem.note = note
        newItem.quantity = quantity ?? 0
        newItem.obtained = obtained
        newItem.buyPrice = buyPrice ?? 0.0
        newItem.buyCurrency = buyCurrency
        newItem.uuid = UUID()
        newItem.image = imageData
        
        let kindEntityList = kind.compactMap {
            var kindEntity: Kind?
            if let kindId = $0.id {
                kindEntity = get(entity: .Kind, id: kindId)
            }
            return kindEntity
        }
        
        var brandEntity: Brand?
        if let brandId = brand?.id {
            brandEntity = get(entity: .Brand, id: brandId)
        }
        
        var sellerEntity: Seller?
        if let sellerId = seller?.id {
            sellerEntity = get(entity: .Seller, id: sellerId)
        }
       
        addItemViewModel.save(item: newItem, kind: kindEntityList, brand: brandEntity, seller: sellerEntity) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.updated.toggle()
                }
            case .failure(let error):
                self.logger.error("While saving a new item, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new item with name = \(String(describing: name))"
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    public func saveKind(name: String) -> Void {
        let created = Date()
        
        let newKind = Kind(context: addItemViewModel.viewContext)
        newKind.created = created
        newKind.lastupd = created
        newKind.name = name.trimmingCharacters(in: .whitespaces)
        newKind.uuid = UUID()
        
        addItemViewModel.save(kind: newKind) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.updated.toggle()
                    self.fetchKinds()
                }
            case .failure(let error):
                self.logger.error("While saving a new category, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new category with name = \(String(describing: name))"
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    public func saveBrand(name: String, urlString: String) -> Void {
        let created = Date()
        
        let newBrand = Brand(context: addItemViewModel.viewContext)
        newBrand.created = created
        newBrand.lastupd = created
        newBrand.name = name.trimmingCharacters(in: .whitespaces)
        newBrand.url = URL(string: urlString)
        newBrand.uuid = UUID()

        addItemViewModel.save(brand: newBrand) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.updated.toggle()
                    self.fetchBrands()
                }
            case .failure(let error):
                self.logger.error("While saving a new brand, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new brand with name = \(String(describing: name))"
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                }
            }
        }
    }
    
    public func saveSeller(name: String, urlString: String) -> Void {
        let created = Date()
        
        let newSeller = Seller(context: addItemViewModel.viewContext)
        newSeller.created = created
        newSeller.lastupd = created
        newSeller.name = name.trimmingCharacters(in: .whitespaces)
        newSeller.url = URL(string: urlString)
        newSeller.uuid = UUID()

        addItemViewModel.save(seller: newSeller) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.updated.toggle()
                    self.fetchSellers()
                }
            case .failure(let error):
                self.logger.error("While saving a new seller, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new seller with name = \(String(describing: name))"
                DispatchQueue.main.async {
                    self.showAlert.toggle()
                }
            }
            
        }
    }
    
    // MARK: - ImagePaster
    func hasImage() -> Bool {
        return imagePaster.hasImage()
    }
    
    func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        imagePaster.paste(completionHandler: completionHandler)
    }
    
    func getData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        imagePaster.getData(from: info, completionHandler: completionHandler)
    }
}

