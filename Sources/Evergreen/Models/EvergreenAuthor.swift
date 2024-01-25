//
//  EvergreenAuthor.swift
//  
//
//  Created by Brian Hasenstab on 1/11/23.
//

import Foundation

public class EvergreenAuthor: Codable {
    public var name: String
    public var email: String
    
    public static var authorAndEmailMatch = try! NSRegularExpression(pattern: "[a-zA-Z0-9 ]*<[a-zA-Z0-9_\\-.+]*@[a-zA-Z0-9\\-.]*\\.[a-zA-Z]{2,}>")
    public static var emailMatch = try! NSRegularExpression(pattern: "[a-zA-Z0-9_\\-.+]*@[a-zA-Z0-9\\-.]*\\.[a-zA-Z]{2,}")
    
    public init(name: String = "", email: String = "") {
        self.name = name
        self.email = email
    }
}
