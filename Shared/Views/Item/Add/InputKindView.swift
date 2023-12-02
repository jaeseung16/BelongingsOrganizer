//
//  InputKindView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputKindView: View {
    @EnvironmentObject private var viewModel: BelongingsViewModel
    
    @Binding var kind: [Kind]
    let geometry: GeometryProxy
    @State private var presentChooseKindView = false
    
    var body: some View {
        VStack {
            HStack {
                Text("CATEGORY")
                    .font(.caption)
                Spacer()
                Button {
                    viewModel.fetchAllKinds()
                    presentChooseKindView = true
                } label: {
                    Label("add", systemImage: "plus")
                }
            }
            
            if kind.isEmpty {
                Text("category")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, idealHeight: 50)
                    .background { CommonRoundedRectangle() }
            } else {
                ForEach(kind) { kind in
                    Text(kind.name ?? "N/A")
                        .frame(maxWidth: .infinity, idealHeight: 50)
                        .background { CommonRoundedRectangle() }
                }
            }
        }
        .sheet(isPresented: $presentChooseKindView, content: {
            ChooseKindView(kinds: $kind)
                .environmentObject(viewModel)
                .frame(width: geometry.size.width, height: geometry.size.height)
        })
    }
}
