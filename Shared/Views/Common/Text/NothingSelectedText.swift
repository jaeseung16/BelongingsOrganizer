//
//  NotSelectedView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/10/21.
//

import SwiftUI

struct NothingSelectedText: View {
    static let notSelected = "Nothing Selected"
    
    var body: some View {
        Text(NothingSelectedText.notSelected)
            .foregroundColor(.secondary)
    }
}
