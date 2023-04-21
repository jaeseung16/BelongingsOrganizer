//
//  StatsType.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 3/27/23.
//

import Foundation

enum StatsType: CaseIterable, Identifiable {
    case obtained, disposed
    
    var id: Self { self }
}
