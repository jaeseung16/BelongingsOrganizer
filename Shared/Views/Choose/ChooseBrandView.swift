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
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var brands: FetchedResults<Brand>
    
    @State var presentAddBrand = false
    
    @Binding var brand: Brand?
    
    @State private var showAlertForDeletion = false
    
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
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected brand"),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { brands[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
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
