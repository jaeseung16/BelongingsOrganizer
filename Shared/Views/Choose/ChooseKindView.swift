//
//  ChooseItemView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct ChooseKindView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))],
        animation: .default)
    private var kinds: FetchedResults<Kind>
    
    @State var presentAddItem = false
    
    @Binding var kind: Kind?
    
    @State private var showAlertForDeletion = false
    
    var body: some View {
        VStack {
            Text("Choose a category")
                .font(.title3)
            
            Divider()
            
            selectedView()
                .frame(minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 10.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Divider()
            
            kindList()
            
            Divider()
            
            SheetBottom(labelText: "Add a category") {
                presentAddItem = true
            } done: {
                dismiss.callAsFunction()
            }
        }
        .padding()
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected category"),
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
           
            if kind == nil {
                NothingSelectedText()
            } else {
                Button {
                    kind = nil
                } label: {
                    Text((kind!.name ?? ""))
                }
            }
        }
    }
    
    private func kindList() -> some View {
        List {
            ForEach(kinds) { kind in
                Button {
                    self.kind = kind
                } label: {
                    Text(kind.name ?? "")
                }
            }
            .onDelete(perform: deleteItems)
        }
        .sheet(isPresented: $presentAddItem, content: {
            AddKindView()
                .environmentObject(AddItemViewModel.shared)
        })
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.delete(offsets.map { kinds[$0] }) { error in
                let nsError = error as NSError
                print("While deleting a category, occured an unresolved error \(nsError), \(nsError.userInfo)")
                showAlertForDeletion.toggle()
            }
        }
    }
}

struct ChooseKindView_Previews: PreviewProvider {
    @State private static var kind: Kind?
    
    static var previews: some View {
        ChooseKindView(kind: ChooseKindView_Previews.$kind)
    }
}
