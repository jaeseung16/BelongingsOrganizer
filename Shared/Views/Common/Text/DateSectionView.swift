//
//  DateView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/1/23.
//

import SwiftUI

struct DateSectionView: View {
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var sectionTitle: SectionTitle
    var date: Date
    
    var body: some View {
        HStack {
            Spacer()
            
            SectionTitleView(title: sectionTitle)
            
            Text("\(date, formatter: DateSectionView.dateFormatter)")
        }
    }
}
