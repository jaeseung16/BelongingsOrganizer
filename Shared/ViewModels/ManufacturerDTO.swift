//
//  ManufacturerDTO.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation

struct ManufacturerDTO: Identifiable, CustomStringConvertible {
    var id: UUID
    var name: String
    var url: URL
    
    var description: String {
        "ManufacturerDTO[id: \(id), name: \(name), url: \(url)]"
    }
}
