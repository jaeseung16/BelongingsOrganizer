//
//  DetailDateView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/20/23.
//

import SwiftUI

struct DetailDateView: View {
    
    let title: SectionTitle
    let originalDate: Date?
    @Binding var date: Date
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentObtainedDatePickerView = false
    
    var body: some View {
        VStack {
            HStack {
                SectionTitleView(title: title)
                
                Spacer()
                if isEdited {
                    Text("\(date, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else if let originalDate {
                    Text("\(originalDate, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
                
                Button {
                    date = originalDate ?? Date()
                    presentObtainedDatePickerView = true
                } label: {
                    Text("edit")
                }
                .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $presentObtainedDatePickerView) {
            EditDateView(date: $date, originalDate: originalDate, isEdited: $isEdited)
        }
        .onChange(of: date) { _ in
            isEdited = true
        }
    }
}
