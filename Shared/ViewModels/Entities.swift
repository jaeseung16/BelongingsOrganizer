//
//  Entities.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation
import CoreData

enum Entities: String {
    case item = "Item"
    case kind = "Kind"
    case brand = "Brand"
    case seller = "Seller"
    
    var type: NSManagedObject.Type {
        switch self {
        case .item:
            return Item.self
        case .kind:
            return Kind.self
        case .brand:
            return Brand.self
        case .seller:
            return Seller.self
        }
    }
}
