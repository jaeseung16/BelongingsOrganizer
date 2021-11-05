//
//  BrandListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct BrandListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var brands: FetchedResults<Brand>

    @State var presentAddBrandView = false

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    List {
                        ForEach(brands) { brand in
                            if let brandName = brand.name {
                                NavigationLink(destination: BrandDetailView(brand: brand,
                                                                            name: brandName,
                                                                            urlString: brand.url?.absoluteString ?? "")) {
                                    Text(brandName)
                                }
                            }
                        }
                        .onDelete(perform: deleteBrands)
                    }
                    .sheet(isPresented: $presentAddBrandView, content: {
                        AddBrandView()
                            .environmentObject(AddItemViewModel.shared)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Brands")
            }
        }
        .onChange(of: AddItemViewModel.shared.showAlert) { _ in
            showAlert = AddItemViewModel.shared.showAlert
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Unable to Save Data"),
                  message: Text(AddItemViewModel.shared.message),
                  dismissButton: .default(Text("Dismiss")))
        }
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected brand"),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                AddItemViewModel.shared.reset()
                presentAddBrandView = true
            }) {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { brands[$0] }) { _ in
                showAlertForDeletion.toggle()
            }
        }
    }
}

struct BrandListView_Previews: PreviewProvider {
    static var previews: some View {
        BrandListView()
    }
}
