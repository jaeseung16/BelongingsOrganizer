//
//  SellerListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct SellerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Seller.name, ascending: true)],
        animation: .default)
    private var sellers: FetchedResults<Seller>

    @State var presentAddSelleriew = false

    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    header()
                    
                    List {
                        ForEach(sellers) { seller in
                            NavigationLink(
                                destination: SellerDetailView(seller: seller, name: seller.name ?? "")
                                    .environmentObject(viewModel)) {
                                Text("\(seller.name ?? "")")
                            }
                        }
                        .onDelete(perform: deleteSellers)
                    }
                    .sheet(isPresented: $presentAddSelleriew, content: {
                        AddSellerView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(viewModel)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Seller")
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                presentAddSelleriew = true
            }) {
                Label("Add a seller", systemImage: "plus")
            }
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

struct SellerListView_Previews: PreviewProvider {
    static var previews: some View {
        SellerListView()
    }
}
