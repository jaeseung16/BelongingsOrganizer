//
//  ItemProperty.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/25/21.
//

import Foundation
import SwiftUI

enum ItemProperty: String, CaseIterable, Identifiable {
    case name = "name"
    case photo = "photo"
    case category = "category"
    case brand = "brand"
    case seller = "seller"
    case quantity = "quantity"
    case obtained = "ontained"
    case buyPrice = "buy price"
    case disposed = "disposed"
    case sellPrice = "sell price"
    case note = "note"
    
    var id: String {
        self.rawValue
    }
}
