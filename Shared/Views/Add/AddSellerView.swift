//
//  AddSellerView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct AddSellerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var url = ""
    
    var body: some View {
        VStack {
            Text("Name")
            
            TextField("Name", text: $name)
            
            Text("URL")
            
            TextField("URL", text: $url)
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Cancel")
                })
                
                Button(action: {
                    saveSeller()
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Save")
                })
            }
        }
        .padding()
    }
    
    private func saveSeller() -> Void {
        let created = Date()
        
        let newSeller = Seller(context: viewContext)
        newSeller.created = created
        newSeller.lastupd = created
        newSeller.name = name
        newSeller.url = URL(string: url)
        newSeller.uuid = UUID()

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

struct AddSellerView_Previews: PreviewProvider {
    static var previews: some View {
        AddSellerView()
    }
}