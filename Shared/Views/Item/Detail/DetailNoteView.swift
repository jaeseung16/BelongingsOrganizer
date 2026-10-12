//
//  DetailNoteView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailNoteView: View {
    let originalNote: String?
    @Binding var note: String
    @Binding var isEdited: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            SectionTitleView(title: .note)
            
            TextField(originalNote ?? "", text: $note)
                .onSubmit {
                    isEdited = true
                }
                .frame(maxWidth: .infinity)
                .background { CommonRoundedRectangle() }
        }
    }
}
