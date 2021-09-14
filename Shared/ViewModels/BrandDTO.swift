//
//  BrandDTO.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation

struct BrandDTO: Identifiable, CustomStringConvertible {
    var id: UUID?
    var name: String?
    var url: URL?
    
    var description: String {
        "BrandDTO[id: \(String(describing: id)), name: \(String(describing: name)), url: \(String(describing: url))]"
    }
}
