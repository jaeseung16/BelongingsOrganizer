//
//  DetailDisposedView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailDisposedView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    var item: Item
    @Binding var disposed: Date
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentDisposedDatePickerView = false
    
    var body: some View {
        VStack {
            HStack {
                SectionTitleView(title: .disposed)

                Spacer()
                
                if isEdited {
                    Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else if let disposed = item.disposed {
                    Text("\(disposed, formatter: BelongingsViewModel.dateFormatterWithDateOnly)")
                } else {
                    Text("N/A")
                }
                Button(action: {
                    disposed = item.disposed ?? Date()
                    presentDisposedDatePickerView = true
                }, label: {
                    Text("edit")
                })
            }
        }
        .sheet(isPresented: $presentDisposedDatePickerView) {
            EditDateView(date: $disposed, originalDate: item.disposed, isEdited: $isEdited)
                .onChange(of: disposed) { _ in
                    isEdited = true
                }
        }
    }
}
