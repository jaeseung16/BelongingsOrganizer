//
//  DefaultRoundedRectangle.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 10/11/23.
//

import SwiftUI

struct CommonRoundedRectangle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5.0)
            .fill(Color(.sRGB, white: 0.5, opacity: 0.1))
    }
}
