//
//  ImageResizing.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/27/23.
//

import Foundation

protocol ImageResizing {
    func tryResize(image: Data) -> Data?
}
