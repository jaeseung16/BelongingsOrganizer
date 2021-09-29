//
//  ChooseItemView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/7/21.
//

import SwiftUI

struct ChooseKindView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
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
            
            Form {
                Section(header: Text("Selected")) {
                    if kind == nil {
                        NothingSelectedText()
                    } else {
                        Text((kind!.name ?? ""))
                    }
                }
            }
            
            Divider()
            
            List {
                ForEach(kinds) { kind in
                    Button(action: {
                        self.kind = kind
                    }, label: {
                        Text(kind.name ?? "")
                    })
                }
                .onDelete(perform: deleteItems)
            }
            .sheet(isPresented: $presentAddItem, content: {
                AddKindView()
                    .environment(\.managedObjectContext, viewContext)
            })
            
            Divider()
            
            SheetBottom(labelText: "Add a category") {
                presentAddItem = true
            } done: {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
        .alert(isPresented: $showAlertForDeletion) {
            Alert(title: Text("Unable to Delete Data"),
                  message: Text("Failed to delete the selected category"),
                  dismissButton: .default(Text("Dismiss")))
        }
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
