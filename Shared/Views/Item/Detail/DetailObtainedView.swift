//
//  DetailObtainedView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailObtainedView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    var item: Item
    @Binding var obtained: Date
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentObtainedDatePickerView = false
    
    var body: some View {
        VStack {
            HStack {
                SectionTitleView(title: .obtained)
                
                Spacer()
                if isEdited {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else if let obtained = item.obtained {
                    Text("\(obtained, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
                
                Button(action: {
                    obtained = item.obtained ?? Date()
                    presentObtainedDatePickerView = true
                }, label: {
                    Text("edit")
                })
            }
        }
        .sheet(isPresented: $presentObtainedDatePickerView) {
            EditDateView(date: $obtained, originalDate: item.obtained, isEdited: $isEdited)
                .onChange(of: obtained) { _ in
                    isEdited = true
                }
        }
    }
}
