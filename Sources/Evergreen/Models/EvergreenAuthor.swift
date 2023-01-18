//
//  EvergreenAuthor.swift
//  
//
//  Created by Brian Hasenstab on 1/11/23.
//

import Foundation

public class EvergreenAuthor: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var email: String
}
