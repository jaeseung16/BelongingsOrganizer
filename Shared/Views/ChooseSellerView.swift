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
        sortDescriptors: [NSSortDescriptor(keyPath: \Seller.name, ascending: true)],
        animation: .default)
    private var sellers: FetchedResults<Seller>
    
    @State var presentAddSeller = false
    
    @Binding var seller: Seller?
    
    var body: some View {
        VStack {
            Text("Selected seller: \(seller == nil ? "" : (seller!.name ?? ""))")
            
            Divider()
                 
            List {
                ForEach(sellers) { seller in
                    Button(action: {
                        self.seller = seller
                    }, label: {
                        Text("\(seller.name ?? "") at \(seller.created!, formatter: dateFormatter)")
                    })
                }
                .onDelete(perform: deleteSellers)
            }
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif

                Button(action: {
                    presentAddSeller = true
                }) {
                    Label("Add a seller", systemImage: "plus")
                }
            }
            .sheet(isPresented: $presentAddSeller, content: {
                AddSellerView()
                    .environment(\.managedObjectContext, viewContext)
            })
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            })
        }
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ChooseSellerView_Previews: PreviewProvider {
    @State private static var seller: Seller?
    
    static var previews: some View {
        ChooseSellerView(seller: ChooseSellerView_Previews.$seller)
    }
}
