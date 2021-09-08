//
//  ChooseItemView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct ChooseItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.created, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State var presentAddItem = false
    
    @Binding var item: Item?
    
    var body: some View {
        VStack {
            Text("Selected item: \(item == nil ? "" : (item!.name ?? ""))")
            
            Divider()
                 
            List {
                ForEach(items) { item in
                    Button(action: {
                        self.item = item
                    }, label: {
                        Text("\(item.name ?? "") at \(item.created!, formatter: itemFormatter)")
                    })
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif

                Button(action: {
                    presentAddItem = true
                }) {
                    Label("Add an item", systemImage: "plus")
                }
            }
            .sheet(isPresented: $presentAddItem, content: {
                AddItemView()
                    .environment(\.managedObjectContext, viewContext)
            })
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ChooseItemView_Previews: PreviewProvider {
    @State private static var item: Item?
    
    static var previews: some View {
        ChooseItemView(item: ChooseItemView_Previews.$item)
    }
}
