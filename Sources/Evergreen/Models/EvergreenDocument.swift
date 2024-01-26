//
//  EvergreenProtocol.swift
//  
//
//  Created by Brian Hasenstab on 1/11/23.
//

import Foundation

public class EvergreenDocument: Codable {
    public var metadata: EvergreenMetadata
    public var content: [EvergreenElement]
    
    public init(metadata: EvergreenMetadata, content: [EvergreenElement]) {
        self.metadata = metadata
        self.content = content
    }
}
