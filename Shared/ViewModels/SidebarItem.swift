//
//  SidebarItem.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/9/23.
//

import Foundation

enum SidebarItem: String, CaseIterable, Identifiable  {
    var id: Self {
        return self
    }
    
    case items = "Items"
    case categories = "Categories"
    case brands = "Brands"
    case sellers = "Sellers"
    case stats = "Stats"
    
    var imageName: String {
        var imageName = ""
        switch self {
        case .items:
            imageName = "gift.fill"
        case .categories:
            imageName = "list.dash"
        case .brands:
            imageName = "r.circle"
        case .sellers:
            imageName = "shippingbox.fill"
        case .stats:
            imageName = "chart.xyaxis.line"
        }
        return imageName
    }
    
}
