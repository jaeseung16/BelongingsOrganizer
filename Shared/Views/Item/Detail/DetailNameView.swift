//
//  DetailNameView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailNameView: View {
    let originalName: String?
    @Binding var name: String
    @Binding var isEdited: Bool
    
    var body: some View {
        HStack {
            SectionTitleView(title: .name)
            
            Spacer()
            
            TextField(originalName ?? "", text: $name, prompt: nil)
                .onSubmit {
                    isEdited = true
                }
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background {
                    CommonRoundedRectangle()
                }
        }
    }
}
