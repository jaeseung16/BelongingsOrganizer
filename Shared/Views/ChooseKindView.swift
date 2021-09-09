//
//  ChooseItemView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct ChooseKindView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Kind.created, ascending: false)],
        animation: .default)
    private var kinds: FetchedResults<Kind>
    
    @State var presentAddItem = false
    
    @Binding var kind: Kind?
    
    var body: some View {
        VStack {
            Text("Selected item: \(kind == nil ? "" : (kind!.name ?? ""))")
            
            Divider()
                 
            List {
                ForEach(kinds) { kind in
                    Button(action: {
                        self.kind = kind
                    }, label: {
                        Text("\(kind.name ?? "") at \(kind.created!, formatter: dateFormatter)")
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
                AddKindView()
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
            offsets.map { kinds[$0] }.forEach(viewContext.delete)

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

struct ChooseKindView_Previews: PreviewProvider {
    @State private static var kind: Kind?
    
    static var previews: some View {
        ChooseKindView(kind: ChooseKindView_Previews.$kind)
    }
}