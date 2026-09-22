//
//  Item+Extensions.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/22/26.
//

import Foundation

// Typed access to Item's relationships. The schema keeps brand and seller to-many (CloudKit
// can't change a relationship's cardinality in place), but the app treats them as single-valued:
// PersistenceHelper.update replaces the whole set, so these read the one element.
extension Item {
    // Sorted by name: the relationship is an unordered set
    var kinds: [Kind] {
        (kind?.compactMap { $0 as? Kind } ?? [])
            .sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
    }

    var firstBrand: Brand? {
        brand?.anyObject() as? Brand
    }

    var firstSeller: Seller? {
        seller?.anyObject() as? Seller
    }
}
