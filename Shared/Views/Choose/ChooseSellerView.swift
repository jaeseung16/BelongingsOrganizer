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
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var sellers: FetchedResults<Seller>
    
    @State var presentAddSeller = false
    
    @Binding var seller: Seller?
    
    @State private var showAlertForDeletion = false
    
    var body: some View {
        VStack {
            Text("Choose a seller")
            
            Divider()
            
            selectedView()
                .frame(minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 10.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Divider()
                 
            sellerList()
            
            Divider()
            
            SheetBottom(labelText: "Add a seller") {
                presentAddSeller = true
            } done: {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected seller"),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
    
    private func selectedView() -> some View {
        VStack {
            HStack {
                Text("SELECTED")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if seller == nil {
                NothingSelectedText()
            } else {
                Button {
                    seller = nil
                } label: {
                    Text((seller!.name ?? ""))
                }
            }
        }
    }
    
    private func sellerList() -> some View {
        List {
            ForEach(sellers) { seller in
                Button {
                    self.seller = seller
                } label: {
                    Text(seller.name ?? "")
                }
            }
            .onDelete(perform: deleteSellers)
        }
        .sheet(isPresented: $presentAddSeller, content: {
            AddSellerView()
                .environmentObject(AddItemViewModel.shared)
        })
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { sellers[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

struct ChooseSellerView_Previews: PreviewProvider {
    @State private static var seller: Seller?
    
    static var previews: some View {
        ChooseSellerView(seller: ChooseSellerView_Previews.$seller)
    }
}
