//
//  SectionTitleView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 11/1/21.
//

import SwiftUI

struct SectionTitleView: View {
    let title: SectionTitle
    var color = Color.secondary
    
    var body: some View {
        Text(title.rawValue)
            .font(.caption)
            .foregroundColor(color)
    }
}
