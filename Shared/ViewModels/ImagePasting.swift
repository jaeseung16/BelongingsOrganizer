//
//  ImagePasting.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 4/2/23.
//

import SwiftUI

protocol ImagePasting {
    func hasImage() -> Bool
    func paste(completionHandler: @escaping (Data?, Error?) -> Void) ->Void 
    func getData(from info: DropInfo, completionHandler: @escaping (Data?, Error?) -> Void) ->Void
}
