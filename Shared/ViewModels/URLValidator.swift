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
    
    static func validatedURL(from urlString: String) async throws -> URL? {
        if isSchemeSupported(urlString) {
            return URL(string: urlString)
        } else {
            if try await isWorkingWithHttps(with: urlString) {
                return URL(string: prefix(urlString, with: .https))
            } else if try await isWorkingWithHttp(with: urlString) {
                return URL(string: prefix(urlString, with: .http))
            }
        }
        return nil
    }
    
    static func validatedURL(from urlString: String, completionHandler: @escaping (URL?) -> Void) -> Void {
        if isSchemeSupported(urlString) {
            completionHandler(URL(string: urlString))
        } else {
            isWorkingWithHttps(with: urlString) { success in
                if success {
                    completionHandler(URL(string: prefix(urlString, with: .https)))
                } else {
                    self.isWorkingWithHttp(with: urlString) { success in
                        completionHandler(success ? URL(string: prefix(urlString, with: .http)) : nil)
                    }
                }
            }
        }
    }
    
    private static func prefix(_ urlString: String, with scheme: Scheme) -> String {
        return "\(scheme.rawValue)\(schemeAuthoritySeparator)\(urlString)"
    }
    
    private static func isSchemeSupported(_ urlString: String) -> Bool {
        guard let urlComponent = URLComponents(string: urlString), let scheme = urlComponent.scheme?.lowercased() else {
            return false
        }
        return scheme == Scheme.http.rawValue || scheme == Scheme.https.rawValue
    }
    
    private static func canDownload(from urlString: String) async throws -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        
        let (_, response) = try await URLSession.shared.data(from: url)
        if let response = response as? HTTPURLResponse, response.statusCode == 200 {
            return true
        }
        
        return false
    }
    
    private static func canDownload(from urlString: String, completionHandler: @escaping (Bool) -> Void) -> Void {
        guard let url = URL(string: urlString) else {
            completionHandler(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
        task.resume()
    }
    
    private static func isWorkingWithHttps(with urlString: String) async throws -> Bool {
        let urlStringPrefixedWithHttps = prefix(urlString, with: Scheme.https)
        return try await canDownload(from: urlStringPrefixedWithHttps)
    }
    
    private static func isWorkingWithHttps(with urlString: String, completionHandler: @escaping (Bool) -> Void) -> Void {
        let urlStringPrefixedWithHttps = prefix(urlString, with: Scheme.https)
        canDownload(from: urlStringPrefixedWithHttps) { completionHandler($0) }
    }
    
    private static func isWorkingWithHttp(with urlString: String) async throws -> Bool {
        let urlStringPrefixedWithHttp = prefix(urlString, with: Scheme.http)
        return try await canDownload(from: urlStringPrefixedWithHttp)
    }
    
    private static func isWorkingWithHttp(with urlString: String, completionHandler: @escaping (Bool) -> Void) -> Void {
        let urlStringPrefixedWithHttp = prefix(urlString, with: Scheme.http)
        canDownload(from: urlStringPrefixedWithHttp) { completionHandler($0) }
    }
}
