//
//  KindDTO.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/9/21.
//

import Foundation

struct KindDTO: Identifiable, CustomStringConvertible, Equatable {
    var id: UUID?
    var name: String?
    var created: Date?
    var lastupd: Date?
    
    var description: String {
        "KindDTO[id: \(String(describing: id)), name: \(String(describing: name)), created: \(String(describing: created)), lastupd: \(String(describing: lastupd))]"
    }
}
