//
//  AddItemView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/6/21.
//

import SwiftUI

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var category = ""
    @State private var maker = ""
    
    var body: some View {
        VStack {
            Text("Name")
            
            TextField("Name", text: $name)
            
            Text("Category")
            
            TextField("Category", text: $category)
            
            Text("Maker")
            
            TextField("Maker", text: $maker)
            
            HStack {
                Button(action: {
                        presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Cancel")
                })
                
                Button(action: {
                        saveItem()
                },
                label: {
                    Text("Save")
                })
            }
        }
        .padding()
        
    }
    
    private func saveItem() -> Void {
        let newItem = Item(context: viewContext)
        newItem.created = Date()
        newItem.lastupd = newItem.created
        newItem.name = name
        newItem.category = category
        newItem.maker = maker

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

struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddItemView()
    }
}
