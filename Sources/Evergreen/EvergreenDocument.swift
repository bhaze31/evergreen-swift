//
//  EvergreenProtocol.swift
//  
//
//  Created by Brian Hasenstab on 1/11/23.
//

import Foundation

public class EvergreenDocument: Codable {
    var metadata: EvergreenMetadata
    var content: [EvergreenElement]
    
    init(metadata: EvergreenMetadata, content: [EvergreenElement]) {
        self.metadata = metadata
        self.content = content
    }
}
