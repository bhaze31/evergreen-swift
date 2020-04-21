//
//  EvergreenConverter.swift
//
//
//  Created by Brian Hasenstab on 4/10/20.
//

public class EvergreenConverter {
    let selfClosingElements = ["hr", "br"]
    
    var elements: [EvergreenElement]
    
    public init(elements: [EvergreenElement]) {
        self.elements = elements
    }
    
    func createImageElement(element: ImageEvergreenElement) -> String {
        var imageStringElement = "<img src=\"\(element.src)\" alt=\"\(element.alt)\""
        
        if let title = element.title {
            imageStringElement += " title=\"\(title)\""
        }

        if element.classes.count > 0 {
            imageStringElement += " class=\"\(element.classes.joined(separator: " "))\""
        }
        
        if let id = element.id {
            imageStringElement += " id=\"\(id)\""
        }
        
        return imageStringElement + " />"
    }
    
    func createAnchorReplacement(element: LinkEvergreenElement) -> String {
        var anchor = "<a href=\"\(element.href)\""
        if let title = element.title {
            anchor += " title=\"\(title)\""
        }
        
        return anchor + ">\(element.text)</a>"
    }
    
    func createElement(element: EvergreenElement) -> String {
        if let imageElement = element as? ImageEvergreenElement {
            return createImageElement(element: imageElement)
        }
        
        if selfClosingElements.contains(element.elementType) {
            return "<\(element.elementType) />"
        }
        
        var stringElement = "<\(element.elementType)"
        
        if element.classes.count > 0 {
            stringElement += " class=\"\(element.classes.joined(separator: " "))\""
        }
        
        if let id = element.id {
            stringElement += " id=\"\(id)\""
        }
        
        stringElement += ">"
        
        if let textElement = element as? TextEvergreenElement {
            stringElement += textElement.text
            if textElement.links.count > 0 {
                for link in textElement.links {
                    let stringLink = createAnchorReplacement(element: link)
                    stringElement = stringElement.replacingOccurrences(of: "<a!>\(link.text)<!a>", with: stringLink)
                }
            }
        }
        
        for childElement in element.children {
            stringElement += createElement(element: childElement)
        }
        
        return stringElement + "</\(element.elementType)>"
    }
    
    public func updateElements(elements: Elements) {
        self.elements = elements
    }
    
    public func convert() -> String {
        return elements.map { element in createElement(element: element) }.joined(separator: "")
    }
}

