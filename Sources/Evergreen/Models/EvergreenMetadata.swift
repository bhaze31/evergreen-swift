//
//  EvergreenMetadata.swift
//
//
//  Created by Brian Hasenstab on 1/24/24.
//

import Foundation

public class EvergreenMetadata: Codable {
    public var authors: [EvergreenAuthor]
    public var title: String
    public var description: String
    public var slug: String
    public var tags: [String]
    public var publishedAtDate: Date
    public var updatedAtDate: Date?
    
    public init(authors: [String], title: String, description: String, slug: String, tags: [String], publishedAtDate: Date, updatedAtDate: Date?) {
        let evergreenAuthors = authors.map { authorString in
            if authorString.isMatching(EvergreenAuthor.authorAndEmailMatch) {
                let parts = authorString.components(separatedBy: "<")
                let name = parts.first!.trim()
                let email = String(parts.last!.trim().dropLast())
                return EvergreenAuthor(name: name, email: email)
            } else if authorString.isMatching(EvergreenAuthor.emailMatch) {
                return EvergreenAuthor(email: authorString)
            } else {
                return EvergreenAuthor(name: authorString)
            }
        }
        
        self.authors = evergreenAuthors
        self.title = title.isEmpty ? "New document \(UUID().uuidString)" : title
        self.description = description

        if slug.isEmpty {
            self.slug = self.title.lowercased()
                .components(separatedBy: " ")
                .map { $0.trim() }
                .joined(separator: "-")
        } else {
            self.slug = slug
        }
        
        self.tags = tags
        self.publishedAtDate = publishedAtDate
        self.updatedAtDate = updatedAtDate
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.authors = try container.decode([EvergreenAuthor].self, forKey: .authors)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.publishedAtDate = try container.decode(Date.self, forKey: .publishedAtDate)
        self.updatedAtDate = try container.decodeIfPresent(Date.self, forKey: .updatedAtDate)
    }
}
