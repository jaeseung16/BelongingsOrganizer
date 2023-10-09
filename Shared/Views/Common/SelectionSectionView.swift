//
//  SelectSectionView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/9/23.
//

import SwiftUI
import CoreData

struct SelectionSectionView<Content: View>: View {
    var title: SectionTitle
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal) {
                LazyHStack {
                    content
                    .background(RoundedRectangle(cornerRadius: 5.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 1.0)))
                }
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 10.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            .frame(maxHeight: 40.0)
        }
    }
}
