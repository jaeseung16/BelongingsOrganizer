//
//  ItemDTO2.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/18/23.
//

import Foundation

struct ItemDTO2: Identifiable, CustomStringConvertible {
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
        "ItemDTO2[id: \(String(describing: id)), name: \(String(describing: name)), quantity: \(String(describing: quantity)), obtained: \(String(describing: obtained)), buyPrice: \(String(describing: buyPrice)), disposed: \(String(describing: disposed)), sellPrice: \(String(describing: sellPrice))]"
    }
}
