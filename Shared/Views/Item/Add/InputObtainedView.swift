//
//  InputObtainedView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/14/23.
//

import SwiftUI

struct InputObtainedView: View {
    @Binding var obtainedDate: Date
    let geometry: GeometryProxy

    var body: some View {
        HStack {
            Text("OBTAINED")
                .font(.caption)
            
            Spacer()
            
            DatePicker("", selection: $obtainedDate, displayedComponents: [.date])
        }
    }
}
