//
//  ItemDTO2.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/18/23.
//

import Foundation

struct ItemDTO: Identifiable, CustomStringConvertible {
    var id: UUID
    var name: String
    var note: String
    var quantity: Int
    var buyPrice: Double
    var sellPrice: Double
    var buyCurrency: String
    var sellCurrency: String
    var obtained: Date
    var disposed: Date
    var image: Data?
    var kind: [Kind]
    var brand: Brand?
    var seller: Seller?
    
    var description: String {
        "ItemDTO[id: \(String(describing: id)), name: \(String(describing: name)), quantity: \(String(describing: quantity)), obtained: \(String(describing: obtained)), buyPrice: \(String(describing: buyPrice)), disposed: \(String(describing: disposed)), sellPrice: \(String(describing: sellPrice))]"
    }
    
    static func create(from item: Item) -> ItemDTO {
        return ItemDTO(id: item.uuid ?? UUID(),
                       name: item.name ?? "",
                       note: item.note ?? "",
                       quantity: Int(item.quantity),
                       buyPrice: item.buyPrice,
                       sellPrice: item.sellPrice,
                       buyCurrency: item.buyCurrency ?? "",
                       sellCurrency: item.sellCurrency ?? "",
                       obtained: item.obtained ?? Date(),
                       disposed: item.disposed ?? Date(),
                       image: item.image,
                       kind: item.kind?.compactMap { $0 as? Kind } ?? [Kind](),
                       brand: item.brand?.compactMap { $0 as? Brand }.first,
                       seller: item.seller?.compactMap { $0 as? Seller }.first)
    }
    
}
