//
//  EvergreenProtocol.swift
//  
//
//  Created by Brian Hasenstab on 1/11/23.
//

import Foundation

public protocol EvergreenDocument: Codable {
    var title: String { get set }
    var authors: [EvergreenAuthor] { get set }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var tags: [EvergreenTag] { get set }
    var content: EvergreenElement { get set }
}
