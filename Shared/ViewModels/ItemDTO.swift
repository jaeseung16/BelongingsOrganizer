//
//  ItemDTO.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation

struct ItemDTO: Identifiable, CustomStringConvertible {
    var id: UUID?
    var name: String?
    var note: String?
    var quantity: Int64?
    var buyPrice: Double?
    var sellPrice: Double?
    var buyCurrency: String?
    var sellCurrency: String?
    var obtained: Date?
    var disposed: Date?
    var image: Data?
    
    var description: String {
        "ItemDTO[id: \(String(describing: id)), name: \(String(describing: name)), quantity: \(String(describing: quantity)), obtained: \(String(describing: obtained)), buyPrice: \(String(describing: buyPrice)), disposed: \(String(describing: disposed)), sellPrice: \(String(describing: sellPrice))]"
    }
}
