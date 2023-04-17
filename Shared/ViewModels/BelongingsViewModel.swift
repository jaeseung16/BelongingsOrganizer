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
    @Published var updated = false {
        didSet {
            fetchEntities()
        }
    }
    var cloudUpdated = false
    
    var message = ""
    
    let persistenceHelper: PersistenceHelper
    let imagePaster = ImagePaster.shared
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.persistenceHelper = PersistenceHelper(persistence: persistence)
        super.init()
        
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .sink { self.fetchUpdates($0) }
            .store(in: &subscriptions)
        
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)
        
        self.persistence.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        fetchEntities()
        
        /*
        $cloudUpdated
            .throttle(for: .seconds(60), scheduler: DispatchQueue.main, latest: true)
            .sink { _ in
                self.logger.info("cloudUpdated=\(self.cloudUpdated)")
                self.fetchEntities()
            }
            .store(in: &subscriptions)
        */
        /*
        $stringToSearch
            .throttle(for: .seconds(2), scheduler: DispatchQueue.main, latest: true)
            .sink { _ in
                self.logger.info("\(self.stringToSearch)")
            }
            .store(in: &subscriptions)
        */
    }
    
    private func fetchEntities() -> Void {
        fetchItems()
        fetchKinds()
        fetchBrands()
        fetchSellers()
    }
    
    @Published var items = [Item]()
    
    func fetchItems() -> Void {
        items = fetch(NSFetchRequest<Item>(entityName: "Item"))
    }
    
    @Published var kinds = [Kind]()
    var filteredKinds: [Kind] {
        kinds.filter {
            if let name = $0.name {
                return checkIfStringToSearchContainedIn(name)
            } else {
                return false
            }
        }
    }
    
    func fetchKinds() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Kind>(entityName: "Kind")
        fetchRequest.sortDescriptors = sortDescriptors
        kinds = fetch(fetchRequest)
    }
    
    @Published var brands = [Brand]()
    var filteredBrands: [Brand] {
        brands.filter {
            if let name = $0.name {
                return checkIfStringToSearchContainedIn(name)
            } else {
                return false
            }
        }
    }
    
    func fetchBrands() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Brand>(entityName: "Brand")
        fetchRequest.sortDescriptors = sortDescriptors
        brands = fetch(fetchRequest)
    }
    
    @Published var sellers = [Seller]()
    var filteredSellers: [Seller] {
        sellers.filter {
            if let name = $0.name {
                return checkIfStringToSearchContainedIn(name)
            } else {
                return false
            }
        }
    }
    
    func fetchSellers() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        
        let fetchRequest = NSFetchRequest<Seller>(entityName: "Seller")
        fetchRequest.sortDescriptors = sortDescriptors
        sellers = fetch(fetchRequest)
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
                
                persistenceHelper.save { result in
                    switch result {
                    case .success(_):
                        self.handleSuccess()
                    case .failure(let error):
                        self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                        self.message = "Cannot update name = \(String(describing: self.itemDTO.name))"
                        self.handle(error: error, completionHandler: nil)
                    }
                }
            }
        }
    }
    
    var kindDTO = KindDTO() {
        didSet {
            if kindDTO.id != nil, let existingEntity: Kind = get(entity: .Kind, id: kindDTO.id!) {
                existingEntity.name = kindDTO.name?.trimmingCharacters(in: .whitespaces)
                existingEntity.lastupd = Date()
                
                persistenceHelper.save { result in
                    switch result {
                    case .success(_):
                        self.handleSuccess()
                    case .failure(let error):
                        self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                        self.message = "Cannot update name = \(String(describing: self.kindDTO.name))"
                        self.handle(error: error, completionHandler: nil)
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
                
                persistenceHelper.save { result in
                    switch result {
                    case .success(_):
                        self.handleSuccess()
                    case .failure(let error):
                        self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                        self.message = "Cannot update name = \(String(describing: self.brandDTO.name)) and url = \(String(describing: self.brandDTO.url))"
                        self.handle(error: error, completionHandler: nil)
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
                
                persistenceHelper.save { result in
                    switch result {
                    case .success(_):
                        self.handleSuccess()
                    case .failure(let error):
                        self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                        self.message = "Cannot update name = \(String(describing: self.sellerDTO.name)) and url = \(String(describing: self.sellerDTO.url))"
                        self.handle(error: error, completionHandler: nil)
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
            DispatchQueue.main.async {
                self.showAlert.toggle()
            }
        }
        
        return fetchedLinks.isEmpty ? nil : fetchedLinks[0]
    }
    
    func delete(_ objects: [NSManagedObject], completionHandler: @escaping (Error) -> Void) -> Void {
        persistenceHelper.delete(objects) { result in
            switch result {
            case .success(_):
                self.handleSuccess()
            case .failure(let error):
                self.logger.log("Error while deleting data: \(error.localizedDescription, privacy: .public)")
                self.handle(error: error, completionHandler: completionHandler)
            }
        }
    }
    
    private func handleSuccess() -> Void {
        DispatchQueue.main.async {
            self.updated.toggle()
        }
    }
    
    private func handle(error: Error, completionHandler: ((Error) -> Void)?) -> Void {
        DispatchQueue.main.async {
            self.showAlert.toggle()
            if let completionHandler = completionHandler {
                completionHandler(error)
            }
        }
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.cloudUpdated.toggle()
                }
            case .failure(let error):
                self.logger.log("Error while updating history: \(error.localizedDescription, privacy: .public) \(Thread.callStackSymbols, privacy: .public)")
            }
        }
    }
    
    // MARK: -
    public func checkIfStringToSearchContainedIn(_ input: String) -> Bool {
        if stringToSearch == "" {
            return true
        } else {
            return input.lowercased().contains(stringToSearch.lowercased())
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
        return items.filter { item in
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
    
    func getItems(_ kind: Kind) -> [Item] {
        guard let items = kind.items else {
            return [Item]()
        }
        return getSortedItems(items)
    }

    func getItemCount(_ kind: Kind) -> Int {
        guard let items = kind.items else {
            return 0
        }
        return getItemCount(items)
    }

    func getItems(_ brand: Brand) -> [Item] {
        guard let items = brand.items else {
            return [Item]()
        }
        return getSortedItems(items)
    }

    func getItemCount(_ brand: Brand) -> Int {
        guard let items = brand.items else {
            return 0
        }
        return getItemCount(items)
    }

    func getItems(_ seller: Seller) -> [Item] {
        guard let items = seller.items else {
            return [Item]()
        }
        return getSortedItems(items)
    }

    func getItemCount(_ seller: Seller) -> Int {
        guard let items = seller.items else {
            return 0
        }
        return getItemCount(items)
    }

    private func getSortedItems(_ items: NSSet) -> [Item] {
        return items.compactMap { $0 as? Item }
            .sorted { ($0.obtained ?? Date()) > ($1.obtained ?? Date()) }
    }

    private func getItemCount(_ items: NSSet) -> Int {
        return items.compactMap { $0 as? Item }.count
    }

    // MARK: - PersistenceHelper
    public var imageData: Data? {
        return persistenceHelper.imageData
    }
    
    public func updateImage(_ imageData: Data?) {
        persistenceHelper.imageData = imageData
    }
    
    public func saveBelonging(name: String, kind: [Kind], brand: Brand?, seller: Seller?, note: String, obtained: Date, buyPrice: Double?, quantity: Int64?, buyCurrency: String) -> Void {
        let created = Date()
        
        let newItem = Item(context: persistenceHelper.viewContext)
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
       
        persistenceHelper.save(item: newItem, kind: kind, brand: brand, seller: seller) { result in
            switch result {
            case .success(()):
                self.handleSuccess()
            case .failure(let error):
                self.logger.error("While saving a new item, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new item with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    public func saveKind(name: String) -> Void {
        let created = Date()
        
        let newKind = Kind(context: persistenceHelper.viewContext)
        newKind.created = created
        newKind.lastupd = created
        newKind.name = name.trimmingCharacters(in: .whitespaces)
        newKind.uuid = UUID()
        
        persistenceHelper.save() { result in
            switch result {
            case .success(()):
                self.handleSuccess()
            case .failure(let error):
                self.logger.error("While saving a new category, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new category with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    public func saveBrand(name: String, urlString: String) -> Void {
        let created = Date()
        
        let newBrand = Brand(context: persistenceHelper.viewContext)
        newBrand.created = created
        newBrand.lastupd = created
        newBrand.name = name.trimmingCharacters(in: .whitespaces)
        newBrand.url = URL(string: urlString)
        newBrand.uuid = UUID()

        persistenceHelper.save() { result in
            switch result {
            case .success(()):
                self.handleSuccess()
            case .failure(let error):
                self.logger.error("While saving a new brand, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new brand with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
            }
        }
    }
    
    public func saveSeller(name: String, urlString: String) -> Void {
        let created = Date()
        
        let newSeller = Seller(context: persistenceHelper.viewContext)
        newSeller.created = created
        newSeller.lastupd = created
        newSeller.name = name.trimmingCharacters(in: .whitespaces)
        newSeller.url = URL(string: urlString)
        newSeller.uuid = UUID()

        persistenceHelper.save() { result in
            switch result {
            case .success(()):
                self.handleSuccess()
            case .failure(let error):
                self.logger.error("While saving a new seller, occured an unresolved error \(error, privacy: .public)")
                self.message = "Cannot save a new seller with name = \(String(describing: name))"
                self.handle(error: error, completionHandler: nil)
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

