//
//  SellerListView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/11/21.
//

import SwiftUI

struct SellerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var sellers: FetchedResults<Seller>

    @State var presentAddSelleriew = false

    @State private var showAlert = false
    @State private var showAlertForDeletion = false
    
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
                            .environmentObject(AddItemViewModel.shared)
                            .frame(minWidth: 350, minHeight: 450)
                            .padding()
                    })
                }
                .navigationTitle("Seller")
            }
        }
        .onReceive(viewModel.$changedPeristentContext) { _ in
            presentationMode.wrappedValue.dismiss()
        }
        .onChange(of: AddItemViewModel.shared.showAlert) { _ in
            showAlert = AddItemViewModel.shared.showAlert
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Unable to Save Data"),
                  message: Text(AddItemViewModel.shared.message),
                  dismissButton: .default(Text("Dismiss")))
        }
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected seller"),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
    
    private func header() -> some View {
        HStack {
            Button(action: {
                AddItemViewModel.shared.reset()
                presentAddSelleriew = true
            }) {
                Label("Add a seller", systemImage: "plus")
            }
        }
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { sellers[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a seller, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

struct SellerListView_Previews: PreviewProvider {
    static var previews: some View {
        SellerListView()
    }
}
