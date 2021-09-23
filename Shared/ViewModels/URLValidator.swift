//
//  URLValidator.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/23/21.
//

import Foundation

class URLValidator {
    static func validate(urlString: String) -> URL? {
        print("urlString = \(urlString)")
        var validatedURL: URL?
        
        if isValid(urlString: urlString) {
            validatedURL = URL(string: urlString)
        } else {
            if canDownloadHTML(from: "https://\(urlString)") {
                validatedURL = URL(string: "https://\(urlString)")
            } else if canDownloadHTML(from: "http://\(urlString)") {
                validatedURL = URL(string: "http://\(urlString)")
            }
        }
        return validatedURL
    }
    
    private static func isValid(urlString: String) -> Bool {
        guard let urlComponent = URLComponents(string: urlString), let scheme = urlComponent.scheme else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }
    
    private static func canDownloadHTML(from urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            let urlContent = try? String(contentsOf: url)
            return urlContent != nil
        } else {
            return false
        }
    }
}
