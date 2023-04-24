//
//  ChooseSellerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct ChooseSellerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @State var presentAddSeller = false
    
    @Binding var seller: Seller?
    
    @State private var showAlertForDeletion = false
    
    var body: some View {
        GeometryReader { geometry in
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
                    dismiss.callAsFunction()
                }
            }
            .padding()
            .sheet(isPresented: $presentAddSeller, content: {
                #if os(macOS)
                AddSellerView()
                    .frame(minWidth: 0.5 * geometry.size.width)
                    .environmentObject(viewModel)
                #else
                AddSellerView()
                    .environmentObject(viewModel)
                #endif
            })
            .alert(isPresented: $showAlertForDeletion) {
                Alert(title: Text("Unable to Delete Data"),
                      message: Text("Failed to delete the selected seller"),
                      dismissButton: .default(Text("Dismiss")))
            }
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
            ForEach(viewModel.sellers) { seller in
                Button {
                    self.seller = seller
                } label: {
                    Text(seller.name ?? "")
                }
            }
            .onDelete(perform: deleteSellers)
        }
    }
    
    private func deleteSellers(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { viewModel.sellers[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

