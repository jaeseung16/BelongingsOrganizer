//
//  ChooseBrandView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct ChooseBrandView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel

    @State var presentAddBrand = false
    
    @Binding var brand: Brand?
    
    @State private var showAlertForDeletion = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Choose a brand")
                    .font(.title3)
                
                Divider()
                
                selectedView()
                    .frame(minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 10.0)
                                    .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
                
                Divider()
                
                brandList()
                
                Divider()
                
                SheetBottom(labelText: "Add a brand") {
                    presentAddBrand = true
                } done: {
                    dismiss.callAsFunction()
                }
            }
            .padding()
            .sheet(isPresented: $presentAddBrand, content: {
                #if os(macOS)
                AddBrandView()
                    .frame(minWidth: 0.5 * geometry.size.width)
                    .environmentObject(viewModel)
                #else
                AddBrandView()
                    .environmentObject(viewModel)
                #endif
            })
            .alert(isPresented: $showAlertForDeletion) {
                Alert(title: Text("Unable to Delete Data"),
                      message: Text("Failed to delete the selected brand"),
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
            
            if brand == nil {
                NothingSelectedText()
            } else {
                Button {
                    brand = nil
                } label: {
                    Text((brand!.name ?? ""))
                }
            }
        }
    }
    
    private func brandList() -> some View {
        List {
            ForEach(viewModel.brands) { brand in
                Button {
                    self.brand = brand
                } label: {
                    Text(brand.name ?? "")
                }
            }
            .onDelete(perform: deleteBrands)
        }
    }
    
    private func deleteBrands(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { viewModel.brands[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

