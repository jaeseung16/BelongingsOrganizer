//
//  InputNameView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/11/23.
//

import SwiftUI

struct InputNameView: View {
    @Binding var name: String
    
    var body: some View {
        VStack {
            HStack {
                Text("NAME")
                    .font(.caption)
                Spacer()
            }
            
            TextField("name", text: $name)
                .background(CommonRoundedRectangle())
        }
    }
}
