//
//  SortItemsView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 3/13/23.
//

import SwiftUI

struct SortItemsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var sortType: SortType
    @Binding var sortDirection: SortDirection
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header
                
                Divider()
                
                pickers(in: geometry)
                
            }
            .padding()
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss.callAsFunction()
            } label: {
                Text("Dismiss")
            }
            
            Spacer()
            
            Button {
                sortType = .lastupd
                sortDirection = .descending
            } label: {
                Text("Reset")
            }
        }
    }
    
    private func pickers(in geometry: GeometryProxy) -> some View {
        HStack {
            VStack {
                Text("Sort By")
                
                Picker("Sort by", selection: $sortType) {
                    Text(SortType.name.rawValue).tag(SortType.name)
                    Text(SortType.obtained.rawValue).tag(SortType.obtained)
                    Text(SortType.lastupd.rawValue).tag(SortType.lastupd)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 0.6 * geometry.size.width)
            }
            
            
            Spacer()
            
            VStack {
                Text("Direction")
                
                Picker("Sort direction", selection: $sortDirection) {
                    Image(systemName: SortDirection.ascending.rawValue).tag(SortDirection.ascending)
                    Image(systemName: SortDirection.descending.rawValue).tag(SortDirection.descending)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 0.3 * geometry.size.width)
            }
            
        }
    }
}

