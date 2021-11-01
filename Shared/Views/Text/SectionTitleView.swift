//
//  SectionTitleView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 11/1/21.
//

import SwiftUI

struct SectionTitleView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
