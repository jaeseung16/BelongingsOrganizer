//
//  DetailHeaderView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 11/5/21.
//

import SwiftUI

struct DetailHeaderView: View {
    
    @Binding var isEdited: Bool
    var reset: () -> Void
    var update: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button {
                reset()
            } label: {
                Text("Cancel")
            }
            .disabled(!isEdited)
            
            Spacer()
            
            Button {
                update()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!isEdited)
            
            Spacer()
        }
    }
}

