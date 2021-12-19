//
//  BrandListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct BrandListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                          NSSortDescriptor(key: "created", ascending: false)],
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
                    
                    brandListView()
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
            Text("Failed to delete the selected brand")
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
    
    private func brandListView() -> some View {
        List {
            ForEach(brands) { brand in
                if let brandName = brand.name {
                    NavigationLink(destination: BrandDetailView(brand: brand,
                                                                name: brandName,
                                                                urlString: brand.url?.absoluteString ?? "")) {
                        brandRowView(brand, name: brandName)
                    }
                }
            }
            .onDelete(perform: deleteBrands)
        }
    }
    
    private func brandRowView(_ brand: Brand, name: String) -> some View {
        HStack {
            Text(name)
            
            Spacer()
            
            if let items = brand.items {
                Text("\(items.count) items")
                    .font(.callout)
                    .foregroundColor(.secondary)
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
