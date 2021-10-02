//
//  ImagePaster.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/1/21.
//

import SwiftUI
import UniformTypeIdentifiers

class ImagePaster {
    static func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void {
        ImageType.allCases.forEach { imageType in
            UIPasteboard.general.itemProviders.first(where: {
                $0.hasItemConformingToTypeIdentifier(imageType.identifier())
            })?
                .loadDataRepresentation(forTypeIdentifier: imageType.identifier(), completionHandler: completionHandler)
        }
    }
    
    static func hasImage() -> Bool {
        var result = false
        for imageType in ImageType.allCases {
            if UIPasteboard.general.itemProviders.first(where: {$0.hasItemConformingToTypeIdentifier(imageType.identifier())}) != nil {
                result = true
                break
            }
        }
        return result
    }
}
