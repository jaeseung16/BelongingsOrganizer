//
//  KindListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct KindListView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var presentAddKindView = false
    @State private var readyToRefresh = false
    @State private var showAlertForDeletion = false
    @Binding var selected: Kind?
    
    var kinds: [Kind] {
        return viewModel.filteredKinds
    }
    
    var body: some View {
        VStack {
            kindList
                .sheet(isPresented: $presentAddKindView) {
                    AddKindView()
                        .environmentObject(viewModel)
                        .modifier(SheetModifier())
                }
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
            }
        } message: {
            Text("Failed to delete the selected category")
        }
    }
    
    private var kindList: some View {
        VStack {
            List(selection: $selected) {
                ForEach(kinds) { kind in
                    NavigationLink(value: kind) {
                        BrandKindSellerRowView(name: kind.name ?? "", itemCount: viewModel.getItemCount(kind))
                    }
                }
                .onDelete(perform: deleteKinds)
            }
            .toolbar {
                header
            }
        }
        .refreshable {
            viewModel.fetchEntities()
        }
        .onChange(of: viewModel.canRefresh) { _ in
            readyToRefresh = viewModel.canRefresh
        }
    }
    
    private var header: ToolbarItemGroup<some View> {
        #if os(macOS)
        ToolbarItemGroup() {
            Button {
                viewModel.fetchEntities()
                viewModel.canRefresh = false
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(!readyToRefresh)
            
            Button {
                presentAddKindView = true
            } label: {
                Label("Add a category", systemImage: "plus")
            }
        }
        #else
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                presentAddKindView = true
            } label: {
                Label("Add a category", systemImage: "plus")
            }
        }
        #endif
    }

    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { kinds[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
