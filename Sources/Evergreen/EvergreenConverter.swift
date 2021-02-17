//
//  EvergreenConverter.swift
//
//
//  Created by Brian Hasenstab on 4/10/20.
//

import Foundation

public class EvergreenConverter {
    let selfClosingElements = ["hr", "br"]
    let boldReplacement = try! NSRegularExpression(pattern: "<b!>.*<!b>", options: [])
    
    var elements: [EvergreenElement]
    
    public init(elements: [EvergreenElement]) {
        self.elements = elements
    }
    
    func updateBoldElement(text: String) -> String {
        return text
    }
    
    func processText(text: String) -> String {
        var updatedText = text
        if text.isMatching(boldReplacement) {
            updatedText = updateBoldElement(text: text)
        }
        
        return updatedText
    }
    
    func setClassesAndId(element: EvergreenElement, line _line: String) -> String {
        var line = _line
        if element.classes.count > 0 {
            line += " class=\"\(element.classes.joined(separator: " "))\""
        }
        
        if let id = element.id {
            line += " id=\"\(id)\""
        }
        
        return line
    }
    
    func createAnchorElement(element: EvergreenElement) -> String {
        let href = element.src ?? ""
        let text = element.alt ?? ""
        var anchorStringElement = "<a href=\"\(href)\" "
        
        if let title = element.title {
            anchorStringElement += "title=\"\(title)\" "
        }
        
        return setClassesAndId(element: element, line: anchorStringElement).trim() + ">\(text)</a>"
    }
    
    func createImageElement(element: EvergreenElement) -> String {
        let src = element.src ?? ""
        let alt = element.alt ?? ""
        var imageStringElement = "<img src=\"\(src)\" alt=\"\(alt)\""
        
        if let title = element.title {
            imageStringElement += " title=\"\(title)\""
        }
        
        return setClassesAndId(element: element, line: imageStringElement).trim() + " />"
    }
    
    func createTableElement(element: EvergreenElement) -> String {
        var table = "<table"
        if element.classes.count > 0 {
            table += " class=\"\(element.classes.joined(separator: " "))\""
        }
        
        if let id = element.id {
            table += " id=\"\(id)\""
        }
        
        table += ">"
        
        if element.children.count > 0 {
            element.children.forEach { row in
                var rowElement = "<tr"
                
                if row.classes.count > 0 {
                    rowElement += " class=\"\(row.classes.joined(separator: " "))\""
                }

                if let id = row.id {
                    rowElement += " id=\"\(id)\""
                }
                
                rowElement += ">"

                row.children.forEach { column in
                    let column = column

                    var td = "<\(column.elementType) style=\"text-align:\(column.alignment);\""

                    if column.classes.count > 0 {
                        td += " class=\"\(column.classes.joined(separator: " "))"
                    }
                    
                    if let id = column.id {
                        td += " id=\"\(id)\""
                    }
                    
                    rowElement += td + ">" + column.text + "</td>"
                }
                rowElement += "</tr>"
                table += rowElement
            }
        }
        
        return table + "</table>"
    }
    
    func createAnchorReplacement(element: EvergreenElement) -> String {
        let src = element.src ?? ""
        var anchor = "<a href=\"\(src)\""
        if let title = element.title {
            anchor += " title=\"\(title)\""
        }
        
        let text = element.alt ?? ""
        return anchor + ">\(text)</a>"
    }
    
    func createElement(element: EvergreenElement) -> String {
        if element.elementType == "i" {
            return createImageElement(element: element)
        }
        
        if selfClosingElements.contains(element.elementType) {
            return "<\(element.elementType) />"
        }
        
        if element.elementType == "table" {
            return createTableElement(element: element)
        }
        
        if element.elementType == "img" {
            return createImageElement(element: element)
        }
        
        if element.elementType == "a" {
            let anchorElement = createAnchorElement(element: element)
            guard let identifier = element.identifier, let parent = element.parent else {
                return anchorElement
            }
                
            parent.text = parent.text.replacingOccurrences(of: identifier, with: anchorElement)
        }
        
        var stringElement = "<\(element.elementType)"
        
        if element.classes.count > 0 {
            stringElement += " class=\"\(element.classes.joined(separator: " "))\""
        }
        
        if let id = element.id {
            stringElement += " id=\"\(id)\""
        }
        
        stringElement += ">"
        
        if !element.text.isEmpty {
            stringElement += processText(text: element.text)
        }
        
        for childElement in element.children {
            if let identifier = childElement.identifier {
                let child = createElement(element: childElement)
                stringElement = stringElement.replacingOccurrences(of: identifier, with: child)
            } else {
                stringElement += createElement(element: childElement)
            }
        }
        
        return stringElement + "</\(element.elementType)>"
    }
    
    public func updateElements(elements: Elements) {
        self.elements = elements
    }
    
    public func convert() -> String {
        return elements.map { element in createElement(element: element) }.joined(separator: "\n")
    }
}

