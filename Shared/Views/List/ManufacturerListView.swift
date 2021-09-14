//
//  ManufacturerListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct ManufacturerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Manufacturer.name, ascending: true)],
        animation: .default)
    private var manufacturers: FetchedResults<Manufacturer>

    @State var presentAddManufacturerView = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    List {
                        ForEach(manufacturers) { manufacturer in
                            NavigationLink(
                                destination:  ManufacturerDetailView(manufacturer: manufacturer, name: manufacturer.name ?? "")
                                    .environmentObject(viewModel)) {
                                Text("\(manufacturer.name ?? "")")
                            }
                        }
                        .onDelete(perform: deleteManufactures)
                    }
                    .sheet(isPresented: $presentAddManufacturerView, content: {
                        AddManufacturerView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Manufacturer")
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentAddManufacturerView = true
            }) {
                Label("Add a manufacturer", systemImage: "plus")
            }
        }
    }
    
    private func deleteManufactures(offsets: IndexSet) {
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

struct ManufacturerListView_Previews: PreviewProvider {
    static var previews: some View {
        ManufacturerListView()
    }
}
