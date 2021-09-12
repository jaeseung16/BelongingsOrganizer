//
//  AddItemView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 9/6/21.
//

import SwiftUI

struct AddKindView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    
    var body: some View {
        VStack {
            Text("Name")
            
            TextField("Name", text: $name)
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Cancel")
                })
                
                Button(action: {
                    saveItem()
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Save")
                })
            }
        }
        .padding()
        
    }
    
    private func saveItem() -> Void {
        let created = Date()
        
        let newKind = Kind(context: viewContext)
        newKind.created = created
        newKind.lastupd = created
        newKind.name = name
        newKind.uuid = UUID()
        
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

struct AddKindView_Previews: PreviewProvider {
    static var previews: some View {
        AddKindView()
    }
}
