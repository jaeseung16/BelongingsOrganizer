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

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    List {
                        ForEach(brands) { brand in
                            NavigationLink(
                                destination: BrandDetailView(brand: brand, name: brand.name ?? "")
                                    .environmentObject(viewModel)) {
                                Text("\(brand.name ?? "")")
                            }
                        }
                        .onDelete(perform: deleteBrands)
                    }
                    .sheet(isPresented: $presentAddBrandView, content: {
                        AddBrandView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Brands")
            }
        }
        .onReceive(viewModel.$changedPeristentContext) { _ in
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentAddBrandView = true
            }) {
                Label("Add a brand", systemImage: "plus")
            }
        }
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            offsets.map { brands[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct BrandListView_Previews: PreviewProvider {
    static var previews: some View {
        BrandListView()
    }
}
