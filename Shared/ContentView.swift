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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Belongings.lastupd, ascending: false)],
        animation: .default)
    private var belongings: FetchedResults<Belongings>

    @State var presentAddBelongingView = false

    var body: some View {
        List {
            ForEach(belongings) { belonging in
                Text("\(belonging.name ?? "") at \(belonging.created!, formatter: itemFormatter)")
            }
            .onDelete(perform: deleteBelongings)
        }
        .toolbar {
            #if os(iOS)
            EditButton()
            #endif

            Button(action: {
                presentAddBelongingView = true
            }) {
                Label("Add Belongings", systemImage: "plus")
            }
        }
        .sheet(isPresented: $presentAddBelongingView, content: {
            AddBelongingView()
                .environment(\.managedObjectContext, viewContext)
        })
    }

    private func deleteBelongings(offsets: IndexSet) {
        withAnimation {
            offsets.map { belongings[$0] }.forEach(viewContext.delete)

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
