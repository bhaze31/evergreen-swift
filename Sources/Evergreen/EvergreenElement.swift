//
//  EvergreenElement.swift
//
//
//  Created by Brian Hasenstab on 4/10/20.
//

public class EvergreenElement: Codable {
    var elementType: String
    var parent: EvergreenElement?
    var children: [EvergreenElement] = []
    
    var id: String?
    var classes: [String] = []
    var identifier: String?
    var divIdentifier: String?
    
    var src: String?
    var linkText: String?
    var linkAlt: String?
    
    var text: String = ""
    
    var listType: String?

    var numColumns: Int? {
        get {
            if elementType == "table" {
                return children.first?.children.count
            }
            
            return nil
        }
    }

    var alignment: TableAlignment = .left

    init(elementType: String) {
        self.elementType = elementType
    }
    
    init(elementType: String, text: String) {
        self.elementType = elementType
        self.text = text
    }
    
    init(elementType: String, src: String, linkText: String?, linkAlt: String?) {
        self.elementType = elementType
        self.src = src
        self.linkText = linkText
        self.linkAlt = linkAlt
    }
    
    init(elementType: String, parent: EvergreenElement?) {
        self.elementType = elementType
        self.parent = parent
    }
    
    init(elementType: String, divIdentifier: String) {
        self.elementType = elementType
        self.divIdentifier = divIdentifier
    }
    
    func setImageInformation(src: String, alt: String?, title: String?) {
        self.src = src
        self.linkText = alt
        self.linkAlt = title
    }
}

public enum TableAlignment: String, Codable {
    case left, center, right
}

public typealias Elements = [EvergreenElement]
