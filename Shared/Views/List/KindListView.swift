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
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var kinds: FetchedResults<Kind>

    @State var presentAddKindView = false

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    kindListView()
                    .sheet(isPresented: $presentAddKindView, content: {
                        AddKindView()
                            .environmentObject(AddItemViewModel.shared)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Categories")
            }
        }
        .onChange(of: AddItemViewModel.shared.showAlert) { _ in
            showAlert = AddItemViewModel.shared.showAlert
        }
        .alert("Unable to Save Data", isPresented: $showAlert) {
            Button("Dismiss") {
                showAlert.toggle()
            }
        } message: {
            Text(AddItemViewModel.shared.message)
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
                AddItemViewModel.shared.reset()
                presentAddKindView = true
            }) {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func kindListView() -> some View {
        List {
            ForEach(kinds) { kind in
                if let kindName = kind.name {
                    NavigationLink(destination: KindDetailView(kind: kind, name: kindName)) {
                        kindRowView(kind, name: kindName)
                    }
                }
            }
            .onDelete(perform: deleteKinds)
        }
    }
    
    private func kindRowView(_ kind: Kind, name: String) -> some View {
        HStack {
            Text(name)
            
            Spacer()
            
            if let items = kind.items {
                Text("\(items.count) items")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func deleteKinds(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { kinds[$0] }) { _ in
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
