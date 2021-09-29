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
    @EnvironmentObject var viewModel: AddItemViewModel
    
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
                    saveKind()
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Save")
                })
            }
        }
        .padding()
        
    }
    
    private func saveKind() -> Void {
        viewModel.saveKind(name: name)
    }
    
}

struct AddKindView_Previews: PreviewProvider {
    static var previews: some View {
        AddKindView()
    }
}
