//
//  EvergreenProcessor.swift
//
//
//  Created by Brian Hasenstab on 4/10/20.
//

import Foundation

public class EvergreenProcessor {
    // MARK: Constants
    enum ListType {
        case O_LIST, U_LIST
    }
    
    // MARK: List Variables
    var inList = false
    var currentList: ListEvergreenElement?
    var currentListType: ListType?
    var currentListIndentLength = 0
    var currentSubList = 0
    
    // MARK: Blockquote Variables
    var inBlockquote = false
    var currentBlockquote: BlockquoteEvergreenElement?
    var currentBlockquoteIndentLength = 0
    var currentSubQuote = 0
    var shouldAppendParagraph = false
    
    // MARK: Div Variables
    var inDiv = false
    var currentDiv: DivEvergreenElement?
    
    // MARK: Regular Expressions
    var listMatch = try! NSRegularExpression(pattern: "^([0-9]+\\.|(-|\\+|\\*))", options: [])
    var orderedMatch = try! NSRegularExpression(pattern: "^[0-9]+\\.", options: [])

    var blockMatch = try! NSRegularExpression(pattern: "^>+", options: [])

    var horizontalMatch = try! NSRegularExpression(pattern: "^(\\*{3,}|-{3,}|_{3,})$", options: [])

    var breakMatch = try! NSRegularExpression(pattern: " {2,}$", options: [])
    
    var altMatch = try! NSRegularExpression(pattern: "!?\\[.+\\]", options: [])
    var descMatch = try! NSRegularExpression(pattern: "\\(.+\\)", options: [])
    
    
    var linkMatch = try! NSRegularExpression(pattern: "\\[[\\w\\s\"']+\\]\\([\\w\\s\\/:\\.\"']+\\)", options: [])
    
    var imageMatch = try! NSRegularExpression(pattern: "^!\\[.+\\]\\(.+\\)$", options: [])
    
    var linkImageMatch = try! NSRegularExpression(pattern: "^\\[!\\[[\\w\\s\"']+\\]\\([\\w\\s\\/:\\.\"']+\\)\\]\\([\\w\\s\\/:\\.\"']+\\)$", options: [])
    
    var divMatch = try! NSRegularExpression(pattern: "^<<-[A-Za-z0-9]{3}", options: [])
    
    // MARK: Content
    var lines: [String] = [] {
        didSet {
            elements = Elements()
        }
    }
    var elements = Elements()
    
    public init(lines: [String]) {
        self.lines = lines
    }
    
    public init(lines: String) {
        self.lines = lines.components(separatedBy: .newlines)
    }
    
    // MARK: <a> Element
    func parseLinks(element: TextEvergreenElement) {
        var lineCopy = element.text
        var links = [LinkEvergreenElement]()

        while let match = linkMatch.firstMatch(in: lineCopy, options: [], range: NSRange(location: 0, length: lineCopy.count)) {
            let altInfo = altMatch.firstMatch(in: lineCopy, options: [], range: match.range)!
            let descInfo = descMatch.firstMatch(in: lineCopy, options: [], range: match.range)!
            
            let altText = String(lineCopy[Range(altInfo.range, in: lineCopy)!]).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            let descText = String(lineCopy[Range(descInfo.range, in: lineCopy)!]).replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            
            let descParts = descText.split(separator: " ")
            let href = String(descParts.first ?? "")
            var title: String?

            if descParts.count > 1 {
                title = descParts[1...descParts.count - 1].joined(separator: " ")
            }

            links.append(LinkEvergreenElement(text: altText, href: href, title: title))
            
            lineCopy = linkMatch.stringByReplacingMatches(in: lineCopy, options: [], range: match.range, withTemplate: "<a!>\(altText)<!a>")
        }
        
        element.links = links
        element.text = lineCopy
    }
    
    // MARK: <h#> Element
    func parseHeader(_ line: String) -> TextEvergreenElement {
        let headerMatch = try! NSRegularExpression(pattern: "^#+", options: [])
        let range = NSRange(location: 0, length: line.count)
        let matches = headerMatch.matches(in: line, options: [], range: range)
        let match = matches.first!
        
        
        var text = line.replacingOccurrences(of: "#", with: "", options: [], range: Range<String.Index>(match.range, in: line))
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let header = TextEvergreenElement(elementType: "h\(match.range.length)", text: text)
        parseLinks(element: header)
        return header
    }
    
    // MARK: <p> Element
    func parseParagraphElement(_ line: String) -> TextEvergreenElement {
        let text = TextEvergreenElement(elementType: "p", text: line)
        parseLinks(element: text)
        return text
    }
    
    // MARK: <img /> Element
    func parseImageElement(_ line: String) -> ImageEvergreenElement {
        var src = "", alt = "", title = ""
        let range = NSRange(location: 0, length: line.count)
        let altInfo = altMatch.firstMatch(in: line, options: [], range: range)
        if let match = altInfo {
            alt = String(line[Range(match.range, in: line)!]).replacingOccurrences(of: "![", with: "").replacingOccurrences(of: "]", with: "")
        }
        let descInfo = descMatch.firstMatch(in: line, options: [], range: range)
        if let match = descInfo {
            let description = String(line[Range(match.range, in: line)!])
            let descriptionParts = description.split(separator: " ")
            src = String(descriptionParts.first ?? "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            if descriptionParts.count > 1 {
                let titleParts = descriptionParts[1...descriptionParts.count - 1]
                title = titleParts.joined(separator: " ").replacingOccurrences(of: ")", with: "")
            }
        }
        
        return ImageEvergreenElement(elementType: "img", src: src, alt: alt, title: title)
    }
    
    // MARK: Text Elements
    func parseTextElement(_ line: String) -> EvergreenElement {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.starts(with: "#") {
            return parseHeader(trimmed)
        } else if let _ = imageMatch.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
            return parseImageElement(line)
        }
        
        return parseParagraphElement(line)
    }
    
    func nextListType(_ line: String) -> ListType {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let range = NSRange(location: 0, length: trimmed.count)
        guard let _ = orderedMatch.firstMatch(in: trimmed, options: [], range: range) else {
            return .U_LIST
        }
        
        return .O_LIST
    }

    func parseListItem(_ line: String) -> ListItemEvergreenElement {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let listMatch = try! NSRegularExpression(pattern: "^([0-9]+\\.|(-|\\+|\\*))", options: [])
        let range = NSRange(location: 0, length: trimmed.count)
        let text = listMatch.stringByReplacingMatches(in: trimmed, options: [], range: range, withTemplate: "")
        
        let listItem = ListItemEvergreenElement(text)
        parseLinks(element: listItem)
        return listItem
    }
    
    func parseListElement(_ line: String) {
        let listType = nextListType(line)
        
        if line.starts(with: " ") && inList {
            let indentRegex = try! NSRegularExpression(pattern: " +", options: [])
            let indentLength = indentRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count))!.range.length
            
            if currentListIndentLength < indentLength {
                // We are indenting more than before, create a sub list
                currentSubList += 1

                // Hold access to parent list, this should never fail since we increased indentation and are in a list
                if let parentList = currentList {
                    // Get last created element in current parent list to attach new list to
                    let listItem = parentList.children[parentList.children.count - 1]
                    
                    // Create a new sublist
                    currentList = listType == .O_LIST ? getOrderedList(parentList) : getUnorderedList(parentList)
                    
                    // Add sub list to children of previous item
                    listItem.children.append(currentList!)
                }
            } else if currentListIndentLength > indentLength {
                // TODO: Handle going back multiple lists
                currentSubList -= 1
                let childList = currentList
                currentList = childList?.parentList
            }
            
            currentList?.children.append(parseListItem(line))
            currentListIndentLength = indentLength
        } else if inList && currentSubList > 0 {
            // We have moved back to the base list, loop until root parent
            var parentList: ListEvergreenElement? = currentList?.parentList
            while parentList?.parentList != nil {
                parentList = parentList?.parentList
            }
            
            currentList = parentList
            
            currentListIndentLength = 0
            currentSubList = 0
            
            currentList?.children.append(parseListItem(line))
        } else if !inList || listType != currentListType {
            currentList = listType == .O_LIST ? getOrderedList() : getUnorderedList()
            currentListType = listType
            inList = true
            
            currentList?.children.append(parseListItem(line))
            addToElements(currentList!)
        } else {
            currentList?.children.append(parseListItem(line))
        }
    }
    
    func getOrderedList(_ parentElement: ListEvergreenElement? = nil) -> ListEvergreenElement {
        return ListEvergreenElement(elementType: "ol", parentList: parentElement)
    }
    
    func getUnorderedList(_ parentElement: ListEvergreenElement? = nil) -> ListEvergreenElement  {
        return ListEvergreenElement(elementType: "ul", parentList: parentElement)
    }
    
    // MARK: <blockquote> Element
    func parseBlockquoteElement(_ line: String) {
        let quoteRegex = try! NSRegularExpression(pattern: "^>+", options: [])
        let quoteIndent = quoteRegex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count))!.range.length
        
        let trimmed = blockMatch.stringByReplacingMatches(in: line, options: [], range: NSRange(location: 0, length: line.count), withTemplate: "")
        
        if inBlockquote && currentBlockquoteIndentLength < quoteIndent {
            // Create a new blockquote within the current one
            let parentQuote = currentBlockquote
            let currentQuote = BlockquoteEvergreenElement(parentQuote: parentQuote)
            currentBlockquote = currentQuote
            
            parentQuote?.children.append(currentQuote)
            
            currentQuote.children.append(parseParagraphElement(trimmed))

            currentBlockquoteIndentLength = quoteIndent
        } else if inBlockquote && currentBlockquoteIndentLength > quoteIndent {
            // Go back to the parent blockquote
            var currentQuote = currentBlockquote
            var quoteDifference = currentBlockquoteIndentLength - quoteIndent
            while quoteDifference > 0 {
                
                guard currentQuote?.parentQuote != nil else {
                    break
                }
                
                currentQuote = currentQuote?.parentQuote
                quoteDifference -= 1
            }
            
            currentBlockquote = currentQuote
            
            currentBlockquote?.children.append(parseParagraphElement(trimmed))
            
            currentBlockquoteIndentLength = quoteIndent
        } else if inBlockquote {
            // In current blockqupte, check if we should append to current text
            if trimmed == "" {
                // We are adding another paragraph element
                shouldAppendParagraph = true
            } else if shouldAppendParagraph { // Append to the current quote
                // We have a blank line, create a new paragraph in this blockquote level
                shouldAppendParagraph = false
                    
                currentBlockquote?.children.append(parseParagraphElement(trimmed))
            } else if let children = currentBlockquote?.children, let paragraph = children.last as? TextEvergreenElement {
                paragraph.text += " \(trimmed)"
            }
        } else {
            let blockquote = BlockquoteEvergreenElement()
            
            let paragraph = parseParagraphElement(trimmed)
            blockquote.children.append(paragraph)
            
            inBlockquote = true
            currentBlockquote = blockquote
            currentBlockquoteIndentLength = quoteIndent
            addToElements(blockquote)
        }
    }
    
    // MARK: <div> Element
    func parseDivElement(_ line: String) {
        let identifier = line.replacingOccurrences(of: "<<-", with: "")
        addToElements(DivEvergreenElement(elementType: "div", identifier: identifier))
    }
    
    // MARK: Handle items in DIV
    func addToElements(_ element: EvergreenElement) {
        if inDiv {
            // We are currently in a div
            if let divElement = element as? DivEvergreenElement, divElement.identifier == currentDiv?.identifier {
                // We are in the div, closing
                // If there is a parent div, set that to the current div
                if let parentDiv = currentDiv?.parentDiv {
                    currentDiv = parentDiv
                } else {
                    currentDiv = nil
                    inDiv = false
                }
            } else {
                currentDiv?.children.append(element)
                if let divElement = element as? DivEvergreenElement {
                    divElement.parentDiv = currentDiv
                    currentDiv = divElement
                }
            }
        } else {
            elements.append(element)
            
            if let divElement = element as? DivEvergreenElement {
                inDiv = true
                currentDiv = divElement
            }
        }
    }

    func parseElement(_ line: String)  {
        let range = NSRange(location: 0, length: line.count)
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRange = NSRange(location: 0, length: trimmed.count)

        if let _ = horizontalMatch.firstMatch(in: line, options: [], range: range) {
            addToElements(EvergreenElement(elementType: "hr"))
        } else if let _ = divMatch.firstMatch(in: line, options: [], range: range) {
            parseDivElement(trimmed)
        } else if let _ = listMatch.firstMatch(in: trimmed, options: [], range: trimmedRange) {
            parseListElement(line)
        } else if let _ = blockMatch.firstMatch(in: line, options: [], range: range) {
            parseBlockquoteElement(line)
        } else if line.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            resetAllSpecialElements()
            addToElements(parseTextElement(trimmed))
        } else {
            resetAllSpecialElements()
        }
        
        if let _ = breakMatch.firstMatch(in: line, options: [], range: range) {
            addToElements(EvergreenElement(elementType: "br"))
        }
    }

    public func parse() -> Elements {
        elements = Elements()
        resetAllSpecialElements()
        inDiv = false

        lines.forEach { line in
            parseElement(line)
        }
        
        return elements
    }
    
    private
    
    func resetAllSpecialElements() {
        self.inList = false
        self.currentList = nil
        self.currentListType = nil
        self.currentListIndentLength = 0
        self.currentSubList = 0
        
        self.inBlockquote = false
        self.currentBlockquote = nil
        self.currentBlockquoteIndentLength = 0
        self.currentSubQuote = 0
        self.shouldAppendParagraph = false
    }
}
