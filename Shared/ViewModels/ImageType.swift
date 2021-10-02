//
//  ImageType.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/2/21.
//

import UniformTypeIdentifiers

enum ImageType: CaseIterable {
    case png
    case jpeg
    case webP
    
    func identifier() -> String {
        switch self {
        case .png:
            return UTType.png.identifier
        case .jpeg:
            return UTType.jpeg.identifier
        case .webP:
            return UTType.webP.identifier
        }
    }
}
