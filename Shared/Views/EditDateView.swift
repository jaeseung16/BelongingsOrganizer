//
//  EditDateView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/19/21.
//

import SwiftUI

struct EditDateView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var date: Date
    @State var originalDate: Date?
    
    @Binding var isEdited: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    isEdited = false
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Canel")
                }
                
                Text("Edit Date")
                    
                Button {
                    isEdited = true
                    presentationMode.wrappedValue.dismiss()
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

struct EditDateView_Previews: PreviewProvider {
    @State static var date = Date()
    @State static var isEdited = false
    
    static var previews: some View {
        EditDateView(date: EditDateView_Previews.$date, originalDate: EditDateView_Previews.date, isEdited: EditDateView_Previews.$isEdited)
    }
}
