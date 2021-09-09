//
//  KindDTO.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation

struct KindDTO: Identifiable, CustomStringConvertible {
    var id: UUID
    var name: String
    
    var description: String {
        "KindDTO[id: \(id), name: \(name)]"
    }
}
