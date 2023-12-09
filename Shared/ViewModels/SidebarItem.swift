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
    
    case items, categories, brands, sellers, stats
}
