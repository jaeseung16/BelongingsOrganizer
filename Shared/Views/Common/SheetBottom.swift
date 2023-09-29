//
//  SheetBottom.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct SheetBottom: View {
    var labelText: String
    
    var labelAction: () -> Void
    var done: () -> Void
    
    var body: some View {
        HStack {
            Button(action: labelAction) {
                Label(labelText, systemImage: "plus")
            }
            
            Spacer()
            
            Button(action: done) {
                Text("Done")
            }
        }
    }
}
