//
//  KindListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct KindListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Kind.name, ascending: true)],
        animation: .default)
    private var kinds: FetchedResults<Kind>

    @State var presentAddKindView = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    List {
                        ForEach(kinds) { kind in
                            NavigationLink(
                                destination: KindDetailView(kind: kind, name: kind.name ?? "")
                                    .environmentObject(viewModel)) {
                                Text("\(kind.name ?? "")")
                            }
                        }
                        .onDelete(perform: deleteKinds)
                    }
                    .sheet(isPresented: $presentAddKindView, content: {
                        AddKindView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Categories")
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentAddKindView = true
            }) {
                Label("Add a category", systemImage: "plus")
            }
        }
    }
    
    private func deleteKinds(offsets: IndexSet) {
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

struct KindListView_Previews: PreviewProvider {
    static var previews: some View {
        KindListView()
    }
}
