//
//  BelongingsError.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 3/25/23.
//

import Foundation

enum BelongingsError: Error {
    case noImage
    case notFound(Entities)
}

// Siri and Shortcuts show this text when an intent fails
extension BelongingsError: CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noImage:
            return "No image was found"
        case .notFound(.item):
            return "The item is no longer in Belongings"
        case .notFound(.kind):
            return "The category is no longer in Belongings"
        case .notFound(.brand):
            return "The brand is no longer in Belongings"
        case .notFound(.seller):
            return "The seller is no longer in Belongings"
        }
    }
}
