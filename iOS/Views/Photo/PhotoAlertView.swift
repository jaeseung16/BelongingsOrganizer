//
//  PhotoAlertView.swift
//  Belongings Organizer (macOS)
//
//  Created by Jae Seung Lee on 9/30/21.
//

import SwiftUI

struct PhotoAlertView: View {
    @Binding var isPresenting: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Unable to Load the Photo")
                .font(.headline)
            
            Text("Please try a different photo")
                .font(.callout)
            
            Divider()
            
            Button {
                isPresenting.toggle()
            } label: {
                Text("Dismiss")
            }
            
            Spacer()
        }
    }
}
