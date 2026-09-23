//
//  ImageResizing.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/27/23.
//

import Foundation

nonisolated protocol ImageResizing {
    func tryResize(image: Data) -> Data?
}
