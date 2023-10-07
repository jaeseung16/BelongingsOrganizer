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
        fetchEntitiesToFilterItems()
    }
    
    func fetchEntities() -> Void {
        fetchItems()
        fetchKinds()
        fetchBrands()
        fetchSellers()
    }
    
    func fetchEntitiesToFilterItems() -> Void {
        fetchAllKinds()
        fetchAllBrands()
        fetchAllSellers()
    }
    
    @Published var items = [Item]()
    func fetchItems() -> Void {
        let fetchRequest = persistenceHelper.getFetchRequest(for: Item.self, entityName: "Item", sortDescriptors: [])
        items = persistenceHelper.perform(fetchRequest)
    }
    
    @Published var allItems = [Item]()
    func fetchAllItems() -> Void {
        let fetchRequest = persistenceHelper.getFetchRequest(for: Item.self, entityName: "Item", sortDescriptors: [])
        allItems = persistenceHelper.perform(fetchRequest)
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
        let fetchRequest = persistenceHelper.getFetchRequest(for: Kind.self, entityName: "Kind", sortDescriptors: sortDescriptors)
        kinds = persistenceHelper.perform(fetchRequest)
    }
    
    @Published var allKinds = [Kind]()
    func fetchAllKinds() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Kind.self, entityName: "Kind", sortDescriptors: sortDescriptors)
        allKinds = persistenceHelper.perform(fetchRequest)
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
        let fetchRequest = persistenceHelper.getFetchRequest(for: Brand.self, entityName: "Brand", sortDescriptors: sortDescriptors)
        brands = persistenceHelper.perform(fetchRequest)
    }
    
    @Published var allBrands = [Brand]()
    func fetchAllBrands() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Brand.self, entityName: "Brand", sortDescriptors: sortDescriptors)
        allBrands = persistenceHelper.perform(fetchRequest)
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
        let fetchRequest = persistenceHelper.getFetchRequest(for: Seller.self, entityName: "Seller", sortDescriptors: sortDescriptors)
        sellers = persistenceHelper.perform(fetchRequest)
    }
    
    @Published var allSellers = [Seller]()
    func fetchAllSellers() -> Void {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                               NSSortDescriptor(key: "created", ascending: false)]
        let fetchRequest = persistenceHelper.getFetchRequest(for: Seller.self, entityName: "Seller", sortDescriptors: sortDescriptors)
        allSellers = persistenceHelper.perform(fetchRequest)
    }
    
    var itemDTO = ItemDTO() {
        didSet {
            if itemDTO.id != nil, let existingEntity = persistenceHelper.get(entity: .item, id: itemDTO.id!) as? Item {
                persistenceHelper.update(existingEntity, to: itemDTO) { result in
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
            if kindDTO.id != nil, let existingEntity = persistenceHelper.get(entity: .kind, id: kindDTO.id!) as? Kind {
                persistenceHelper.update(existingEntity, to: kindDTO) { result in
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
            if brandDTO.id != nil, let existingEntity = persistenceHelper.get(entity: .brand, id: brandDTO.id!) as? Brand {
                persistenceHelper.update(existingEntity, to: brandDTO) { result in
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
            if sellerDTO.id != nil, let existingEntity = persistenceHelper.get(entity: .seller, id: sellerDTO.id!) as? Seller {
                persistenceHelper.update(existingEntity, to: sellerDTO) { result in
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
            self.fetchEntities()
            self.fetchEntitiesToFilterItems()
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
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { result in
            switch result {
            case .success(()):
                return
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
    
    public func itemCountsByKind(type: StatsType, from start: Date, to end: Date) -> [KindStats] {
        var result = [KindStats]()
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)
        
        var itemsByKind = [String: Int]()
        for item in itemsBetweenStartAndEnd {
            if let kindSet = item.kind {
                for kind in kindSet {
                    if let kind = kind as? Kind, let name = kind.name {
                        if let itemcount = itemsByKind[name] {
                            itemsByKind[name] = itemcount + 1
                        } else {
                            itemsByKind[name] = 1
                        }
                    }
                }
            }
        }
        
        let itemCountsByKind = itemsByKind.map { (name, itemCount) in
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
        let endDate = calendar.date(byAdding: DateComponents(day: 1), to: calendar.startOfDay(for: end))!
        return items.filter { item in
            if let obtained = item.obtained {
                return calendar.compare(startDate, to: obtained, toGranularity: .hour) != .orderedDescending && calendar.compare(obtained, to: endDate, toGranularity: .hour) != .orderedDescending
            } else {
                return false
            }
        }
    }
    
    private func itemsDisposedBetween(from start: Date, to end: Date) -> [Item] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        return items.filter { item in
            if let obtained = item.disposed {
                return calendar.compare(startDate, to: obtained, toGranularity: .hour) != .orderedDescending && calendar.compare(obtained, to: endDate, toGranularity: .hour) != .orderedDescending
            } else {
                return false
            }
        }
    }
    
    public func itemCountByBrand(type: StatsType, from start: Date, to end: Date) -> [BrandStats] {
        var result = [BrandStats]()
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)
        
        var itemsByBrand = [String: Int]()
        for item in itemsBetweenStartAndEnd {
            if let brandSet = item.brand {
                for brand in brandSet {
                    if let brand = brand as? Brand, let name = brand.name {
                        if let itemcount = itemsByBrand[name] {
                            itemsByBrand[name] = itemcount + 1
                        } else {
                            itemsByBrand[name] = 1
                        }
                    }
                }
            }
        }
        
        let itemCountsByBrand = itemsByBrand.map { (name, itemCount) in
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
    
    public func itemCountBySeller(type: StatsType, from start: Date, to end: Date) -> [SellerStats] {
        var result = [SellerStats]()
        let itemsBetweenStartAndEnd = type == .obtained ? itemsObtainedBetween(from: start, to: end) : itemsDisposedBetween(from: start, to: end)
        
        var itemsBySeller = [String: Int]()
        for item in itemsBetweenStartAndEnd {
            if let sellerSet = item.seller {
                for seller in sellerSet {
                    if let seller = seller as? Seller, let name = seller.name {
                        if let itemcount = itemsBySeller[name] {
                            itemsBySeller[name] = itemcount + 1
                        } else {
                            itemsBySeller[name] = 1
                        }
                    }
                }
            }
        }
        
        let itemCountsBySeller =  itemsBySeller.map { (name, itemCount) in
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
    
    public func saveBelonging(name: String, kind: [Kind], brand: Brand?, seller: Seller?, note: String, obtained: Date, buyPrice: Double?, quantity: Int64?, buyCurrency: String, image: Data?) -> Void {
        let item = ItemDTO(id: UUID(), name: name, note: note, quantity: quantity, buyPrice: buyPrice, buyCurrency: buyCurrency, obtained: obtained, image: image)
        persistenceHelper.save(item, kind: kind, brand: brand, seller: seller) { result in
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
        let kind = KindDTO(id: UUID(), name: name.trimmingCharacters(in: .whitespaces))
        persistenceHelper.save(kind) { result in
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
        let brand = BrandDTO(id: UUID(), name: name.trimmingCharacters(in: .whitespaces), url: URL(string: urlString))
        persistenceHelper.save(brand) { result in
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
        let seller = SellerDTO(id: UUID(), name: name.trimmingCharacters(in: .whitespaces), url: URL(string: urlString))
        persistenceHelper.save(seller) { result in
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
    
    // MARK: - URL Vaildation
    func validatedURL(from urlString: String, completionHandler: @escaping (URL?) -> Void) -> Void {
        URLValidator.validatedURL(from: urlString) { completionHandler($0) }
    }
    
    func validatedURL(from urlString: String) async -> URL? {
        do {
            return try await URLValidator.validatedURL(from: urlString)
        } catch {
            logger.error("Failed to validate url=\(urlString): \(error, privacy: .public)")
            return nil
        }
    }
}

