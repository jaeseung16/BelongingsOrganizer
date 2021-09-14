//
//  ChooseBrandView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct ChooseBrandView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Brand.name, ascending: true)],
        animation: .default)
    private var brands: FetchedResults<Brand>
    
    @State var presentAddBrand = false
    
    @Binding var brand: Brand?
    
    var body: some View {
        VStack {
            Text("Choose a brand")
                .font(.title3)
            
            Divider()
            
            Form {
                Section(header: Text("Selected")) {
                    if brand == nil {
                        NothingSelectedText()
                    } else {
                        Text(brand!.name ?? "")
                    }
                }
            }
            
            List {
                ForEach(brands) { brand in
                    Button(action: {
                        self.brand = brand
                    }, label: {
                        Text(brand.name ?? "")
                    })
                }
                .onDelete(perform: deleteBrands)
            }
            .sheet(isPresented: $presentAddBrand, content: {
                AddBrandView()
                    .environment(\.managedObjectContext, viewContext)
            })
            
            Divider()
            
            SheetBottom(labelText: "Add a brand") {
                presentAddBrand = true
            } done: {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
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

struct ChooseBrandView_Previews: PreviewProvider {
    @State private static var brand: Brand?
    
    static var previews: some View {
        ChooseBrandView(brand: ChooseBrandView_Previews.$brand)
    }
}
