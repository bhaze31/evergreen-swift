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
    var currentList: EvergreenElement?
    var currentListType: ListType?
    var currentListIndentLength = 0
    var currentSubList = 0
    
    // MARK: Blockquote Variables
    var inBlockquote = false
    var currentBlockquote: EvergreenElement?
    var currentBlockquoteIndentLength = 0
    var currentSubQuote = 0
    var shouldAppendParagraph = false
    
    // MARK: Div Variables
    var inDiv = false
    var currentDiv: EvergreenElement?
    
    // MARK: Table Variables
    var inTable = false
    var currentTable: EvergreenElement?
    
    // MARK: Regular Expressions
    let listMatch = try! NSRegularExpression(pattern: "^([0-9]+\\.|(-|\\+|\\*))", options: [])
    let orderedMatch = try! NSRegularExpression(pattern: "^[0-9]+\\.", options: [])
    
    let blockMatch = try! NSRegularExpression(pattern: "^>+", options: [])
    
    let horizontalMatch = try! NSRegularExpression(pattern: "^(\\*{3,}|-{3,}|_{3,})$", options: [])
    
    let breakMatch = try! NSRegularExpression(pattern: " {2,}$", options: [])
    
    let altMatch = try! NSRegularExpression(pattern: "!?\\[.+\\]", options: [])
    let descMatch = try! NSRegularExpression(pattern: "\\(.+\\)", options: [])
    
    let linkMatch = try! NSRegularExpression(pattern: "\\[[\\w\\s\"']+\\]\\([\\w\\s\\/:\\.\"']+\\)", options: [])
    
    let imageMatch = try! NSRegularExpression(pattern: "!\\[.+\\]\\(.+\\)", options: [])
    
    let linkImageMatch = try! NSRegularExpression(pattern: "^\\[!\\[[\\w\\s\"']+\\]\\([\\w\\s\\/:\\.\"']+\\)\\]\\([\\w\\s\\/:\\.\"']+\\)$", options: [])

    let tableMatch = try! NSRegularExpression(pattern: "^\\|[\\w\\s-_\\:\\|]+\\|", options: [])
    let tableHeaderMatch = try! NSRegularExpression(pattern: "^\\|(\\:?-{3,}\\:?\\|)+$", options: [])
    let centerTableMatch = try! NSRegularExpression(pattern: "\\:-{3,}\\:", options: [])
    let leftTableMatch = try! NSRegularExpression(pattern: "\\:-{3,}$", options: [])
    let rightTableMatch = try! NSRegularExpression(pattern: "^-{3,}\\:", options: [])

    let divMatch = try! NSRegularExpression(pattern: "^<<-[\\s]*[A-Za-z0-9]{3}", options: [])

    let identifierMatch = try! NSRegularExpression(pattern: "\\{[\\w-_\\s\\.#]+\\}$", options: [])

    let parentIdentifierMatch = try! NSRegularExpression(pattern: "\\{\\{[\\w-_\\s\\.#]+\\}\\}$", options: [])

    let iDMatch = try! NSRegularExpression(pattern: "\\#[\\w-_]+", options: [])
    let classMatch = try! NSRegularExpression(pattern: "\\.[\\w-_]+", options: [])
    
    let italicMatch = try! NSRegularExpression(pattern: "\\*{1}[^\\*]+\\*{1}", options: [])
    let boldMatch = try! NSRegularExpression(pattern: "\\*{2}[^\\*]+\\*{2}", options: [])
    let boldItalicMatch = try! NSRegularExpression(pattern: "\\*{3}[^\\*]+\\*{3}", options: [])

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

    func splitIdentifiersFromLine(line: String, matching classType: NSRegularExpression? = nil) -> (String, String?, [String]) {
        let match = classType ?? identifierMatch
        var id: String?
        var classList = [String]()
        
        line.stringFromMatch(match)
            .replaceSubstrings(["{", "}"])
            .trim()
            .split(separator: " ")
            .map { String($0) }
            .forEach { item in
                if item.isMatching(classMatch) {
                    classList.append(item.replaceSubstrings(["."]))
                } else if item.isMatching(iDMatch) {
                    id = item.replaceSubstrings(["#"])
                }
            }
        
        let text = line.removeAll(matching: match).trim()
        return (text, id, classList)
    }

    func linkParser(line: String, in givenRange: NSRange? = nil) -> (String, String, String?) {
        let range = givenRange ?? line.fullRange()
        let anchorText = line.stringFromMatch(altMatch, in: range).replaceSubstrings(["![", "[", "]"])
        
        let descText = line.stringFromMatch(descMatch, in: range).replaceSubstrings(["(", ")"])
        
        let descParts = descText.split(separator: " ")
        let href = String(descParts.first ?? "")
        var title: String?
        
        if descParts.count > 1 {
            title = descParts[1...descParts.count - 1].joined(separator: " ")
        }
        return (anchorText, href, title)
    }
    
    // MARK: <a> Element
    func parseLinks(element: EvergreenElement) {
        var lineCopy = element.text
        
        while let match = linkMatch.firstMatch(in: lineCopy, options: [], range: lineCopy.fullRange()) {
            let (anchorText, href, altText) = linkParser(line: lineCopy, in: match.range)
            
            let identifier = UUID()
            let link = EvergreenElement(elementType: "a", src: href, alt: altText, title: anchorText)
            link.identifier = identifier.uuidString
        
            element.children.append(link)
            
            lineCopy = lineCopy.replaceFirst(matching: linkMatch, with: identifier.uuidString, in: match.range)
        }
        
        element.text = lineCopy
    }
    
    func splitItalicMatch(line: String, in range: NSRange? = nil) -> String {
        let matchRange = range ?? line.fullRange()

        let italic = italicMatch.firstMatch(in: line, options: [], range: matchRange)
        
        guard italic != nil else { return line }
        
        let identifier = line.stringFromMatch(italicMatch, in: matchRange).replaceSubstrings(["*"]).trim()

        return line.replaceFirst(matching: italicMatch, with: "<i!>\(identifier)<!i>", in: matchRange)
    }
    
    func splitBoldMatch(line: String, in range: NSRange? = nil) -> String {
        let matchRange = range ?? line.fullRange()
        
        let bold = boldMatch.firstMatch(in: line, options: [], range: matchRange)
        
        guard bold != nil else { return line }
        
        let identifier = line.stringFromMatch(boldMatch, in: matchRange).replaceSubstrings(["**"]).trim()
        
        return line.replaceFirst(matching: boldMatch, with: "<b!>\(identifier)<!b>", in: matchRange)
    }
    
    func splitDoubleMatch(line: String) -> String {
        let match = boldItalicMatch.firstMatch(in: line, options: [], range: line.fullRange())
        var subbedRange = match?.range
        
        if subbedRange != nil {
            subbedRange!.length += 6
        }
        
        return splitBoldMatch(line: splitItalicMatch(line: line, in: match?.range), in: subbedRange)
    }
    
    func parseModifiers(element: EvergreenElement) {
        var lineCopy = element.text
        
        if lineCopy.isMatching(italicMatch) {
            while lineCopy.isMatching(italicMatch) {
                if lineCopy.isMatching(boldItalicMatch) {
                    lineCopy = splitDoubleMatch(line: lineCopy)
                } else if lineCopy.isMatching(boldMatch) {
                    lineCopy = splitBoldMatch(line: lineCopy)
                } else if lineCopy.isMatching(italicMatch) {
                    lineCopy = splitItalicMatch(line: lineCopy)
                }
            }
            
            element.text = lineCopy
        }
    }
    
    // MARK: <h#> Element
    func parseHeader(_ line: String) -> EvergreenElement {
        let headerMatch = try! NSRegularExpression(pattern: "^#+", options: [])
        
        let matches = headerMatch.matches(in: line, options: [], range: line.fullRange())
        let match = matches.first!
        
        let originalText = line.replaceAll(matching: headerMatch, with: "").trim()

        let header = EvergreenElement(elementType: "h\(match.range.length)", text: originalText)

        if originalText.isMatching(identifierMatch) {
            let (trimmed, id, classes) = splitIdentifiersFromLine(line: originalText)
            header.id = id
            header.classes = classes
            header.text = trimmed
        }

        parseLinks(element: header)
        parseModifiers(element: header)
        return header
    }
    
    // MARK: <p> Element
    func parseParagraphElement(_ line: String) -> EvergreenElement {
        let textElement = EvergreenElement(elementType: "p", text: line)
        
        if line.isMatching(identifierMatch) {
            let (trimmed, id, classes) = splitIdentifiersFromLine(line: line)
            textElement.id = id
            textElement.classes = classes
            textElement.text = trimmed
        }

        parseLinks(element: textElement)
        parseModifiers(element: textElement)
        return textElement
    }
    
    // MARK: <img /> Element
    func parseImageElement(_ line: String) -> EvergreenElement {
        let (alt, src, title) = linkParser(line: line)
        let element = EvergreenElement(elementType: "img")
        element.setImageInformation(src: src, alt: alt, title: title)
        return element
    }
    
    // MARK: Text Elements
    func parseTextElement(_ line: String) -> EvergreenElement {
        let trimmed = line.trim()
        
        if trimmed.starts(with: "#") {
            return parseHeader(trimmed)
        } else if line.isMatching(imageMatch) {
            return parseImageElement(line)
        }
        
        return parseParagraphElement(line)
    }
    
    func nextListType(_ line: String) -> ListType {
        let trimmed = line.trim()
        return trimmed.isMatching(orderedMatch) ? .O_LIST : .U_LIST
    }
    
    func parseListItem(_ line: String) -> EvergreenElement {
        let trimmed = line.trim()
        let listMatch = try! NSRegularExpression(pattern: "^([0-9]+\\.|(-|\\+|\\*))", options: [])
        // We need to retrim the characters in whitespace, since after removing the leading item in the list (1., *, etc) there may be whitespace at the start of the text
        let text = trimmed.removeAll(matching: listMatch).trim()
        
        let listItem = EvergreenElement(elementType: "li")
        listItem.text = text
        
        if text.isMatching(identifierMatch) {
            let (trimmedText, id, classes) = splitIdentifiersFromLine(line: text)
            listItem.text = trimmedText
            listItem.id = id
            listItem.classes = classes
        }

        parseLinks(element: listItem)
        parseModifiers(element: listItem)
        return listItem
    }
    
    func parseListElement(_ originalLine: String) {
        var line = originalLine
        let listType = nextListType(line)
        let indentRegex = try! NSRegularExpression(pattern: " +", options: [])
        
        if line.starts(with: " ") && inList {
            let indentLength = indentRegex.firstMatch(in: line, options: [], range: line.fullRange())!.range.length
            
            if currentListIndentLength < indentLength {
                // We are indenting more than before, create a sub list
                currentSubList += 1
                
                // Hold access to parent list, this should never fail since we increased indentation and are in a list
                if let parentList = currentList {
                    // Get last created element in current parent list to attach new list to
                    let listItem = parentList.children[parentList.children.count - 1]
                    
                    // Create a new sublist
                    currentList = listType == .O_LIST ? getOrderedList(parentList) : getUnorderedList(parentList)
                    
                    if line.isMatching(parentIdentifierMatch) {
                        let (trimmedLine, id, classes) = splitIdentifiersFromLine(line: line, matching: parentIdentifierMatch)
                        currentList?.id = id
                        currentList?.classes = classes
                        line = trimmedLine
                    }
                    
                    // Add sub list to children of previous item
                    listItem.children.append(currentList!)
                }
            } else if currentListIndentLength > indentLength {
                // TODO: Handle going back multiple lists
                currentSubList -= 1
                let childList = currentList
                currentList = childList?.parent
            }
            
            currentList?.children.append(parseListItem(line))
            currentListIndentLength = indentLength
        } else if inList && currentSubList > 0 {
            // We have moved back to the base list, loop until root parent
            var parentList: EvergreenElement? = currentList?.parent
            while parentList?.parent != nil {
                parentList = parentList?.parent
            }
            
            currentList = parentList
            
            currentListIndentLength = 0
            currentSubList = 0
            
            currentList?.children.append(parseListItem(line))
        } else if !inList || listType != currentListType {
            currentList = listType == .O_LIST ? getOrderedList() : getUnorderedList()
            currentListType = listType
            inList = true
            if line.starts(with: " ") {
                let indentLength = indentRegex.firstMatch(in: line, options: [], range: line.fullRange())!.range.length
                currentListIndentLength = indentLength
            }
            
            if line.isMatching(parentIdentifierMatch) {
                let (trimmedLine, id, classes) = splitIdentifiersFromLine(line: line, matching: parentIdentifierMatch)
                currentList?.id = id
                currentList?.classes = classes
                line = trimmedLine
                currentList?.children.append(parseListItem(line))
            } else {
                currentList?.children.append(parseListItem(line))
            }

            addToElements(currentList!)
        } else {
            currentList?.children.append(parseListItem(line))
        }
    }
    
    func getOrderedList(_ parentElement: EvergreenElement? = nil) -> EvergreenElement {
        return EvergreenElement(elementType: "ol", parent: parentElement)
    }
    
    func getUnorderedList(_ parentElement: EvergreenElement? = nil) -> EvergreenElement  {
        return EvergreenElement(elementType: "ul", parent: parentElement)
    }
    
    // MARK: <blockquote> Element
    func parseBlockquoteElement(_ line: String) {
        let quoteRegex = try! NSRegularExpression(pattern: "^>+", options: [])
        let quoteIndent = quoteRegex.firstMatch(in: line, options: [], range: line.fullRange())!.range.length
        
        let trimmed = line.removeAll(matching: blockMatch).trim()
        
        if inBlockquote && currentBlockquoteIndentLength < quoteIndent {
            // Create a new blockquote within the current one
            let parentQuote = currentBlockquote
            let currentQuote = EvergreenElement(elementType: "blockquote", parent: parentQuote)
            currentBlockquote = currentQuote
            
            parentQuote?.children.append(currentQuote)
            
            if trimmed.isMatching(parentIdentifierMatch) {
                let (removedIDText, id, classes) = splitIdentifiersFromLine(line: trimmed, matching: parentIdentifierMatch)
                currentQuote.children.append(parseParagraphElement(removedIDText))
                currentQuote.id = id
                currentQuote.classes = classes
            } else {
                currentQuote.children.append(parseParagraphElement(trimmed))
            }
            
            currentBlockquoteIndentLength = quoteIndent
        } else if inBlockquote && currentBlockquoteIndentLength > quoteIndent {
            // Go back to the parent blockquote
            var currentQuote = currentBlockquote
            var quoteDifference = currentBlockquoteIndentLength - quoteIndent
            while quoteDifference > 0 {
                
                guard currentQuote?.parent != nil else {
                    break
                }
                
                currentQuote = currentQuote?.parent
                quoteDifference -= 1
            }
            
            currentBlockquote = currentQuote
            
            currentBlockquote?.children.append(parseParagraphElement(trimmed))
            
            currentBlockquoteIndentLength = quoteIndent
        } else if inBlockquote {
            // In current blockquote, check if we should append to current text
            if trimmed == "" {
                // We are adding another paragraph element
                shouldAppendParagraph = true
            } else if shouldAppendParagraph {
                // We have a blank line, create a new paragraph in this blockquote level
                shouldAppendParagraph = false
                
                currentBlockquote?.children.append(parseParagraphElement(trimmed))
            } else if let children = currentBlockquote?.children, let paragraph = children.last {
                paragraph.text += " \(trimmed)"
            }
        } else {
            let blockquote = EvergreenElement(elementType: "blockquote")
            
            if trimmed.isMatching(parentIdentifierMatch) {
                let (removedIDText, id, classes) = splitIdentifiersFromLine(line: trimmed, matching: parentIdentifierMatch)
                blockquote.children.append(parseParagraphElement(removedIDText))
                blockquote.id = id
                blockquote.classes = classes
            } else {
                blockquote.children.append(parseParagraphElement(trimmed))
            }
            
            inBlockquote = true
            currentBlockquote = blockquote
            currentBlockquoteIndentLength = quoteIndent
            addToElements(blockquote)
        }
    }
    
    // MARK: <table> Element
    func parseTableElement(_ line: String) {
        if inTable {
            // Only convert items to table header if it is the second row
            if line.isMatching(tableHeaderMatch) && currentTable?.children.count == 1 {
                // At this point, we know we are inTable and there is more than 0 rows
                let headerRow = currentTable!.children.first!
                var columns = headerRow.children

                line.split(separator: "|")
                    .map { String($0) }
                    .enumerated()
                    .forEach { index, item in
                        let element: EvergreenElement
                        if index + 1 > headerRow.children.count {
                            element = EvergreenElement(elementType: "td", text: "")
                            columns.append(element)
                        } else {
                            element = headerRow.children[index]
                        }
                        
                        element.elementType = "th"

                        if item.isMatching(centerTableMatch) {
                            element.alignment = .center
                        } else if item.isMatching(leftTableMatch) {
                            element.alignment = .left
                        } else if item.isMatching(rightTableMatch) {
                            element.alignment = .right
                        }
                    }

                headerRow.children = columns
                currentTable?.numColumns = headerRow.children.count

                return
            }
            
            let rowElement = EvergreenElement(elementType: "tr")
            var trimmedLine = line

            if trimmedLine.isMatching(identifierMatch) {
                let (trimmed, rowId, rowClasses) = splitIdentifiersFromLine(line: line)
                rowElement.id = rowId
                rowElement.classes = rowClasses
                trimmedLine = trimmed
            }
            
            trimmedLine.split(separator: "|").enumerated().forEach { index, item in
                let column = EvergreenElement(elementType: "td", text: String(item))
                let firstColumn = currentTable?.children.first?.children[index]
                column.alignment = firstColumn?.alignment ?? .left
                rowElement.children.append(column)
            }
            
            if rowElement.children.count > (currentTable?.numColumns ?? 0) {
                currentTable?.numColumns = rowElement.children.count
            }

            currentTable?.children.append(rowElement)
        } else {
            let tableElement = EvergreenElement(elementType: "table")
            let rowElement = EvergreenElement(elementType: "tr")

            var trimmedLine = line
            if trimmedLine.isMatching(parentIdentifierMatch) {
                let (trimmed, tableId, tableClasses) = splitIdentifiersFromLine(line: trimmedLine, matching: parentIdentifierMatch)
                tableElement.id = tableId
                tableElement.classes = tableClasses
                trimmedLine = trimmed
            }

            if trimmedLine.isMatching(identifierMatch) {
                let (trimmed, rowId, rowClasses) = splitIdentifiersFromLine(line: trimmedLine)
                rowElement.id = rowId
                rowElement.classes = rowClasses
                trimmedLine = trimmed
            }

            trimmedLine.split(separator: "|").forEach { item in
                rowElement.children.append(EvergreenElement(elementType: "td", text: String(item)))
            }
            
            tableElement.numColumns = rowElement.children.count
            tableElement.children.append(rowElement)
            currentTable = tableElement
            inTable = true
            addToElements(tableElement)
        }
    }
    
    // MARK: <div> Element
    func parseDivElement(_ line: String) {
        var identifier = line.replacingOccurrences(of: "<<-", with: "").trim()
        let divElement = EvergreenElement(elementType: "div", divIdentifier: identifier)
        
        if identifier.isMatching(identifierMatch) {
            let (trimmedIdentifier, id, classes) = splitIdentifiersFromLine(line: identifier)
            divElement.identifier = trimmedIdentifier
            divElement.id = id
            divElement.classes = classes
            identifier = trimmedIdentifier
        }
    
        addToElements(divElement)
    }
    
    // MARK: Handle items in DIV
    func addToElements(_ element: EvergreenElement) {
        if inDiv {
            // We are currently in a div
            if element.divIdentifier == currentDiv?.divIdentifier {
                // We are in the div, closing
                // If there is a parent div, set that to the current div
                if let parentDiv = currentDiv?.parent {
                    currentDiv = parentDiv
                } else {
                    currentDiv = nil
                    inDiv = false
                }
            } else {
                currentDiv?.children.append(element)
                if element.elementType == "div" {
                    element.parent = currentDiv
                    currentDiv = element
                }
            }
        } else {
            elements.append(element)
            
            if element.elementType == "div" {
                inDiv = true
                currentDiv = element
            }
        }
    }
    
    func parseElement(_ line: String)  {
        let range = line.fullRange()
        let trimmed = line.trim()

        if line.isMatching(horizontalMatch, in: range) {
            addToElements(EvergreenElement(elementType: "hr"))
        } else if line.isMatching(divMatch, in: range) {
            parseDivElement(trimmed)
        } else if trimmed.isMatching(listMatch) {
            parseListElement(line)
        } else if line.isMatching(blockMatch, in: range) {
            parseBlockquoteElement(line)
        } else if line.isMatching(tableMatch) {
            parseTableElement(line)
        } else if trimmed.count > 0 {
            resetAllSpecialElements()
            addToElements(parseTextElement(trimmed))
        } else {
            resetAllSpecialElements()
        }
        
        if line.isMatching(breakMatch, in: range) {
            addToElements(EvergreenElement(elementType: "br"))
        }
    }
    
    public func updateLines(lines: [String]) {
        self.lines = lines
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
        
        self.inTable = false
    }
}
