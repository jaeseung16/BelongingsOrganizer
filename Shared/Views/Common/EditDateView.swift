//
//  EditDateView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/19/21.
//

import SwiftUI

struct EditDateView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var date: Date
    @State var originalDate: Date?
    
    @Binding var isEdited: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    isEdited = false
                    dismiss.callAsFunction()
                } label: {
                    Text("Canel")
                }
                
                Text("Edit Date")
                    
                Button {
                    isEdited = true
                    dismiss.callAsFunction()
                } label: {
                    Text("Save")
                }
            }
            
            Divider()
            
            #if os(macOS)
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .scaledToFit()
                .frame(width: 150)
            #else
            DatePicker("", selection: $date, displayedComponents: [.date])
                .scaledToFit()
                .frame(width: 150)
            #endif
            
            if originalDate == nil {
                Text("Original Date: N/A")
            } else {
                Text("Original Date: \(originalDate!, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
            }
            
            Text("New Date: \(date, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
            
            Spacer()
        }
        .padding()
    }
}

