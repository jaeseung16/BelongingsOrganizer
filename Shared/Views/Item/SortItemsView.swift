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
                header()
                
                Divider()
                
                HStack {
                    VStack {
                        Text("Sort By")
                        
                        Picker("Sort by", selection: $sortType) {
                            Text("Name").tag(SortType.name)
                            Text("Obtained").tag(SortType.obtained)
                            Text("Updated").tag(SortType.lastupd)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 0.6 * geometry.size.width)
                    }
                    
                    
                    Spacer()
                    
                    VStack {
                        Text("Direction")
                        
                        Picker("Sort direction", selection: $sortDirection) {
                            Image(systemName: "arrow.up.forward").tag(SortDirection.ascending)
                            Image(systemName: "arrow.down.forward").tag(SortDirection.descending)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 0.3 * geometry.size.width)
                    }
                    
                }
                
            }
            .padding()
        }
    }
    
    func header() -> some View {
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
}

