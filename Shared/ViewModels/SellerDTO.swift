//
//  SellerDTO.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation

struct SellerDTO: Identifiable, CustomStringConvertible {
    var id: UUID
    var name: String
    var url: URL
    
    var description: String {
        "SellerDTO[id: \(id), name: \(name), url: \(url)]"
    }
}
