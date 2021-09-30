//
//  URLValidator.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/23/21.
//

import Foundation

class URLValidator {
    enum Scheme: String {
        case http, https
    }
    
    static private var schemeAuthoritySeparator = "://"
    
    static func validate(urlString: String) -> URL? {
        var validatedURL: URL?
        
        if isValid(urlString: urlString) {
            validatedURL = URL(string: urlString)
        } else {
            if canDownloadHTML(from: prefix(urlString, with: Scheme.https)) {
                validatedURL = URL(string: prefix(urlString, with: Scheme.https))
            } else if canDownloadHTML(from: prefix(urlString, with: Scheme.http)) {
                validatedURL = URL(string: prefix(urlString, with: Scheme.http))
            }
        }
        return validatedURL
    }
    
    private static func prefix(_ urlString: String, with scheme: Scheme) -> String {
        return "\(scheme.rawValue)\(schemeAuthoritySeparator)\(urlString)"
    }
    
    private static func isValid(urlString: String) -> Bool {
        guard let urlComponent = URLComponents(string: urlString), let scheme = urlComponent.scheme?.lowercased() else {
            return false
        }
        return scheme == Scheme.http.rawValue || scheme == Scheme.https.rawValue
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
