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
        VStack(alignment: .leading) {
            Spacer()
            
            Text("Add a brand")
                .font(.title3)
            
            Divider()
            
            Text("NAME")
                .font(.caption)
            
            TextField("name", text: $name)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, idealHeight: 50)
                .background(RoundedRectangle(cornerRadius: 5.0)
                                .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))
            
            Text("URL")
                .font(.caption)
            
            TextField("url", text: $urlString) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                if let url = URLValidator.validate(urlString: urlString) {
                    print("url = \(url)")
                    self.urlString = url.absoluteString
                } else {
                    showAlert = true
                }
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, idealHeight: 50)
            .background(RoundedRectangle(cornerRadius: 5.0)
                            .fill(Color(.sRGB, white: 0.5, opacity: 0.1)))

            Divider()
            
            HStack {
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text("Cancel")
                })
                
                Spacer()
                
                Button(action: {
                    saveBrand()
                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                })
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .frame(minHeight: 200.0)
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
