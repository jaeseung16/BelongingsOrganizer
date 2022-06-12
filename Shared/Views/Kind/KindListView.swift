//
//  KindListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct KindListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                          NSSortDescriptor(key: "created", ascending: false)],
        animation: .default)
    private var kinds: FetchedResults<Kind>

    @State var presentAddKindView = false

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    var filteredKinds: Array<Kind> {
        kinds.filter { kind in
            if viewModel.stringToSearch == "" {
                return true
            } else if let name = kind.name {
                return name.lowercased().contains(viewModel.stringToSearch.lowercased())
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    kindListView()
                        .sheet(isPresented: $presentAddKindView) {
                            AddKindView()
                                .environmentObject(viewModel.addItemViewModel)
                                .frame(minWidth: 350, minHeight: 450)
                                .padding()
                            
                        }
                }
                .navigationTitle("Categories")
            }
        }
        .onChange(of: viewModel.addItemViewModel.showAlert) { _ in
            showAlert = viewModel.addItemViewModel.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(viewModel.addItemViewModel.message)
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
                viewModel.addItemViewModel.reset()
                presentAddKindView = true
            }) {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func kindListView() -> some View {
        List {
            ForEach(filteredKinds) { kind in
                if let kindName = kind.name {
                    NavigationLink(destination: KindDetailView(kind: kind, name: kindName)) {
                        KindRowView(kind: kind, name: kindName)
                    }
                }
            }
            .onDelete(perform: deleteKinds)
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

struct KindListView_Previews: PreviewProvider {
    static var previews: some View {
        KindListView()
    }
}
