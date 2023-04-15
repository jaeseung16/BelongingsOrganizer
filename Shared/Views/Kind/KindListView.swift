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

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    @State private var filteredKinds = [Kind]()
    
    @State var selectedKind: Kind?
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                VStack {
                    header()
                    
                    List(selection: $selectedKind) {
                        ForEach(filteredKinds, id: \.self) { kind in
                            NavigationLink(value: kind) {
                                KindRowView(name: kind.name ?? "",
                                            itemCount: viewModel.getItemCount(kind))
                            }
                            .id(UUID())
                        }
                        .onDelete(perform: deleteKinds)
                    }
                    .navigationTitle("Categories")
                }
            } detail: {
                if let kind = selectedKind {
                    KindDetailView(kind: kind,
                                   name: kind.name ?? "",
                                   items: viewModel.getItems(kind))
                    .id(UUID())
                }
            }
        }
        .onReceive(viewModel.$kinds) { _ in
            filteredKinds = viewModel.filteredKinds
        }
        .onChange(of: viewModel.showAlert) { _ in
            showAlert = viewModel.showAlert
        }
        .onReceive(viewModel.$stringToSearch) { _ in
            filteredKinds = viewModel.filteredKinds
        }
        .sheet(isPresented: $presentAddKindView) {
            AddKindView()
                .environmentObject(viewModel)
                .frame(minWidth: 350, minHeight: 450)
                .padding()
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(viewModel.message)
        }
        .alert("Unable to Delete Data", isPresented: $showAlertForDeletion) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text("Failed to delete the selected category")
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                viewModel.persistenceHelper.reset()
                presentAddKindView = true
            }) {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { filteredKinds[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}
