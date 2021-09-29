//
//  AddBrandView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/8/21.
//

import SwiftUI

struct AddBrandView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: AddItemViewModel
    
    @State private var name = ""
    @State private var urlString = ""
    @State private var isEditing = false
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            Text("Name")
            
            TextField("Name", text: $name)
            
            Text("URL")
            
            TextField("URL", text: $urlString) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                if let url = URLValidator.validate(urlString: urlString) {
                    print("url = \(url)")
                    self.urlString = url.absoluteString
                } else {
                    showAlert = true
                }
            }

            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Cancel")
                })
                
                Button(action: {
                    saveBrand()
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Save")
                })
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Invalid URL"),
                  message: Text("Cannot access the URL. Try a different one or leave it empty."),
                  dismissButton: .default(Text("Dismiss")))
        }
    }
    
    private func saveBrand() -> Void {
        viewModel.saveBrand(name: name, urlString: urlString)
    }
}

struct AddBrandView_Previews: PreviewProvider {
    static var previews: some View {
        AddBrandView()
    }
}
