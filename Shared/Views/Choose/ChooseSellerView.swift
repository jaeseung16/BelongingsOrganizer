//
//  ChooseSellerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct ChooseSellerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var sellers: FetchedResults<Seller>
    
    @State var presentAddSeller = false
    
    @Binding var seller: Seller?
    
    @State private var showAlertForDeletion = false
    
    var body: some View {
        VStack {
            Text("Choose a seller")
            
            Form {
                Section(header: Text("Selected")) {
                    if seller == nil {
                        NothingSelectedText()
                    } else {
                        Text(seller!.name ?? "")
                    }
                }
            }
            
            Divider()
                 
            List {
                ForEach(sellers) { seller in
                    Button(action: {
                        self.seller = seller
                    }, label: {
                        Text(seller.name ?? "")
                    })
                }
                .onDelete(perform: deleteSellers)
            }
            .sheet(isPresented: $presentAddSeller, content: {
                AddSellerView()
                    .environment(\.managedObjectContext, viewContext)
            })
            
            Divider()
            
            SheetBottom(labelText: "Add a seller") {
                presentAddSeller = true
            } done: {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected seller"),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { sellers[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

struct ChooseSellerView_Previews: PreviewProvider {
    @State private static var seller: Seller?
    
    static var previews: some View {
        ChooseSellerView(seller: ChooseSellerView_Previews.$seller)
    }
}
