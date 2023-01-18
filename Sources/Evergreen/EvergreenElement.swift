//
//  EvergreenElement.swift
//
//
//  Created by Brian Hasenstab on 4/10/20.
//

public class EvergreenElement: Codable {
    public var elementType: String
    public var parent: EvergreenElement?
    public var children: [EvergreenElement] = []
    
    public var id: String?
    public var classes: [String] = []
    public var identifier: String?
    public var divIdentifier: String?
    
    public var src: String?
    public var linkText: String?
    public var linkAlt: String?
    
    public var text: String = ""
    
    public var listType: String?

    public var numColumns: Int? {
        get {
            if elementType == "table" {
                return children.first?.children.count
            }
            
            return nil
        }
    }

    public var alignment: TableAlignment = .left

    public init(elementType: String) {
        self.elementType = elementType
    }
    
    public init(elementType: String, text: String) {
        self.elementType = elementType
        self.text = text
    }
    
    public init(elementType: String, src: String, linkText: String?, linkAlt: String?) {
        self.elementType = elementType
        self.src = src
        self.linkText = linkText
        self.linkAlt = linkAlt
    }
    
    public init(elementType: String, parent: EvergreenElement?) {
        self.elementType = elementType
        self.parent = parent
    }
    
    public init(elementType: String, divIdentifier: String) {
        self.elementType = elementType
        self.divIdentifier = divIdentifier
    }
    
    public func setImageInformation(src: String, alt: String?, title: String?) {
        self.src = src
        self.linkText = alt
        self.linkAlt = title
    }
}

public enum TableAlignment: String, Codable {
    case left, center, right
}

public typealias Elements = [EvergreenElement]
