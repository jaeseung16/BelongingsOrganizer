//
//  ChooseManufacturerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct ChooseManufacturerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Manufacturer.name, ascending: true)],
        animation: .default)
    private var manufacturers: FetchedResults<Manufacturer>
    
    @State var presentAddManufacturer = false
    
    @Binding var manufacturer: Manufacturer?
    
    var body: some View {
        VStack {
            Text("Selected maker: \(manufacturer == nil ? "" : (manufacturer!.name ?? ""))")
            
            Divider()
                 
            List {
                ForEach(manufacturers) { manufacturer in
                    Button(action: {
                        self.manufacturer = manufacturer
                    }, label: {
                        Text("\(manufacturer.name ?? "") at \(manufacturer.created!, formatter: dateFormatter)")
                    })
                }
                .onDelete(perform: deleteManufacturers)
            }
            .toolbar {
                #if os(iOS)
                EditButton()
                #endif

                Button(action: {
                    presentAddManufacturer = true
                }) {
                    Label("Add a manufacturer", systemImage: "plus")
                }
            }
            .sheet(isPresented: $presentAddManufacturer, content: {
                AddManufacturerView()
                    .environment(\.managedObjectContext, viewContext)
            })
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
            })
        }
    }
    
    private func deleteManufacturers(offsets: IndexSet) {
        withAnimation {
            offsets.map { manufacturers[$0] }.forEach(viewContext.delete)

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

struct ChooseManufacturerView_Previews: PreviewProvider {
    @State private static var manufacturer: Manufacturer?
    
    static var previews: some View {
        ChooseManufacturerView(manufacturer: ChooseManufacturerView_Previews.$manufacturer)
    }
}
