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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var sellers: FetchedResults<Seller>
    
    @State var presentAddSeller = false
    
    @Binding var seller: Seller?
    
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
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            offsets.map { sellers[$0] }.forEach(viewContext.delete)

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

struct ChooseSellerView_Previews: PreviewProvider {
    @State private static var seller: Seller?
    
    static var previews: some View {
        ChooseSellerView(seller: ChooseSellerView_Previews.$seller)
    }
}
