//
//  StatsView.swift
//  Belongings Organizer (iOS)
//
//  Created by Jae Seung Lee on 3/19/23.
//

import Charts
import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: BelongingsViewModel
    
    @Binding var statsType: StatsType
    @Binding var start: Date
    @Binding var end: Date
    
    var body: some View {
        VStack {
            Picker("", selection: $statsType) {
                Text("Obtained").tag(StatsType.obtained)
                Text("Disposed").tag(StatsType.disposed)
            }
            .pickerStyle(.segmented)
            DatePicker("Start Date", selection: $start, displayedComponents: [.date])
            DatePicker("End Date", selection: $end, displayedComponents: [.date])
            Spacer()
        }
        .padding()
    }
    
}
