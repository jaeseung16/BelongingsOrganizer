//
//  ContentView.swift
//  Shared
//
//  Created by Jae Seung Lee on 9/1/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.lastupd, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State var presentAddBelongingView = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                List {
                    ForEach(items) { item in
                        VStack {
                            Text("\(item.name ?? "")")
                            Text("price: \(item.currency ?? "") \(item.buyPrice)")
                            Text("obtained: \(item.obtained ?? Date(), formatter: dateFormatter)")
                            Text("added: \(item.created!, formatter: dateFormatter)")
                        }
                        
                    }
                    .onDelete(perform: deleteBelongings)
                }
                .sheet(isPresented: $presentAddBelongingView, content: {
                    AddItemView(geometry: geometry)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(viewModel)
                        .frame(minWidth: 350, minHeight: 450)
                        .padding()
                })
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    #endif
                    
                    ToolbarItem(placement: .navigation) {
                        Button(action: {
                            presentAddBelongingView = true
                        }) {
                            Label("Add Belongings", systemImage: "plus")
                        }
                    }
                }
                
            }
            .navigationTitle(Text("Belongings"))
        }
        
    }

    private func deleteBelongings(offsets: IndexSet) {
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
