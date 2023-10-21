//
//  DetailKindView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/15/23.
//

import SwiftUI

struct DetailKindView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    let originalKind: [Kind]
    @Binding var kind: [Kind]
    @Binding var isEdited: Bool
    var geometry: GeometryProxy
    
    @State private var presentChooseKindView = false

    var body: some View {
        HStack {
            SectionTitleView(title: .category)
            
            Spacer()
            
            if kind.isEmpty {
                VStack {
                    ForEach(originalKind) {
                        Text($0.name ?? "")
                    }
                }
            } else {
                VStack {
                    ForEach(kind) {
                        Text($0.name ?? "")
                    }
                }
            }
            
            Button {
                kind = originalKind
                presentChooseKindView = true
            } label: {
                Text("edit")
            }
        }
        .sheet(isPresented: $presentChooseKindView) {
            #if os(macOS)
            ChooseKindView(selectedKinds: $kind)
                .frame(minWidth: 0.5 * geometry.size.width, minHeight: geometry.size.height)
                .onChange(of: kind) { _ in
                    isEdited = true
                }
            #else
            ChooseKindView(kinds: $kind)
                .onChange(of: kind) { _ in
                    isEdited = true
                }
            #endif
        }
    }
}