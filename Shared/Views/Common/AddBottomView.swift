//
//  AddBottomView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 12/25/21.
//

import SwiftUI

struct AddBottomView: View {
    var cancel: () -> Void
    var save: () -> Void
    
    var body: some View {
        HStack {
            Button {
                cancel()
            } label: {
                Text("Cancel")
            }
            
            Spacer()
            
            Button {
                save()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
        }
    }
}
