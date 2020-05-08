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
    
    // MARK: Table Variables
    var inTable = false
    var currentTable: TableEvergreenElement?
    
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
    func parseLinks(element: TextEvergreenElement) {
        var lineCopy = element.text
        var links = [LinkEvergreenElement]()
        
        while let match = linkMatch.firstMatch(in: lineCopy, options: [], range: lineCopy.fullRange()) {
            let (anchorText, href, altText) = linkParser(line: lineCopy, in: match.range)

            links.append(LinkEvergreenElement(text: anchorText, href: href, title: altText))
            
            lineCopy = lineCopy.replaceFirst(matching: linkMatch, with: "<a!>\(anchorText.trim())<!a>")
        }
        
        element.links = links
        element.text = lineCopy
    }
    
    // MARK: <h#> Element
    func parseHeader(_ line: String) -> TextEvergreenElement {
        let headerMatch = try! NSRegularExpression(pattern: "^#+", options: [])
        
        let matches = headerMatch.matches(in: line, options: [], range: line.fullRange())
        let match = matches.first!
        
        let originalText = line.replaceAll(matching: headerMatch, with: "").trim()

        let header = TextEvergreenElement(elementType: "h\(match.range.length)", text: originalText)

        if originalText.isMatching(identifierMatch) {
            let (trimmed, id, classes) = splitIdentifiersFromLine(line: originalText)
            header.id = id
            header.classes = classes
            header.text = trimmed
        }

        parseLinks(element: header)
        return header
    }
    
    // MARK: <p> Element
    func parseParagraphElement(_ line: String) -> TextEvergreenElement {
        let textElement = TextEvergreenElement(elementType: "p", text: line)
        
        if line.isMatching(identifierMatch) {
            let (trimmed, id, classes) = splitIdentifiersFromLine(line: line)
            textElement.id = id
            textElement.classes = classes
            textElement.text = trimmed
        }

        parseLinks(element: textElement)
        return textElement
    }
    
    // MARK: <img /> Element
    func parseImageElement(_ line: String) -> ImageEvergreenElement {
        let (alt, src, title) = linkParser(line: line)
        
        return ImageEvergreenElement(elementType: "img", src: src, alt: alt, title: title)
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
    
    func parseListItem(_ line: String) -> ListItemEvergreenElement {
        let trimmed = line.trim()
        let listMatch = try! NSRegularExpression(pattern: "^([0-9]+\\.|(-|\\+|\\*))", options: [])
        // We need to retrim the characters in whitespace, since after removing the leading item in the list (1., *, etc) there may be whitespace at the start of the text
        let text = trimmed.removeAll(matching: listMatch).trim()
        
        let listItem = ListItemEvergreenElement(text)
        
        if text.isMatching(identifierMatch) {
            let (trimmedText, id, classes) = splitIdentifiersFromLine(line: text)
            listItem.text = trimmedText
            listItem.id = id
            listItem.classes = classes
        }

        parseLinks(element: listItem)
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
    
    func getOrderedList(_ parentElement: ListEvergreenElement? = nil) -> ListEvergreenElement {
        return ListEvergreenElement(elementType: "ol", parentList: parentElement)
    }
    
    func getUnorderedList(_ parentElement: ListEvergreenElement? = nil) -> ListEvergreenElement  {
        return ListEvergreenElement(elementType: "ul", parentList: parentElement)
    }
    
    // MARK: <blockquote> Element
    func parseBlockquoteElement(_ line: String) {
        let quoteRegex = try! NSRegularExpression(pattern: "^>+", options: [])
        let quoteIndent = quoteRegex.firstMatch(in: line, options: [], range: line.fullRange())!.range.length
        
        let trimmed = line.removeAll(matching: blockMatch).trim()
        
        if inBlockquote && currentBlockquoteIndentLength < quoteIndent {
            // Create a new blockquote within the current one
            let parentQuote = currentBlockquote
            let currentQuote = BlockquoteEvergreenElement(parentQuote: parentQuote)
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
            // In current blockquote, check if we should append to current text
            if trimmed == "" {
                // We are adding another paragraph element
                shouldAppendParagraph = true
            } else if shouldAppendParagraph {
                // We have a blank line, create a new paragraph in this blockquote level
                shouldAppendParagraph = false
                
                currentBlockquote?.children.append(parseParagraphElement(trimmed))
            } else if let children = currentBlockquote?.children, let paragraph = children.last as? TextEvergreenElement {
                paragraph.text += " \(trimmed)"
            }
        } else {
            let blockquote = BlockquoteEvergreenElement()
            
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
            if line.isMatching(tableHeaderMatch) && currentTable?.rows.count == 1 {
                // At this point, we know we are inTable and there is more than 0 rows
                let headerRow = currentTable!.rows.first!
                var columns = headerRow.columns

                line.split(separator: "|")
                    .map { String($0) }
                    .enumerated()
                    .forEach { index, item in
                        let element: TableItemEvergreenElement
                        if index + 1 > headerRow.columns.count {
                            element = TableItemEvergreenElement(text: "")
                            columns.append(element)
                        } else {
                            element = headerRow.columns[index]
                            
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

                headerRow.columns = columns
                currentTable?.numColumns = headerRow.columns.count

                return
            }
            
            let rowElement = TableRowEvergreenElement()
            var trimmedLine = line

            if trimmedLine.isMatching(identifierMatch) {
                let (trimmed, rowId, rowClasses) = splitIdentifiersFromLine(line: line)
                rowElement.id = rowId
                rowElement.classes = rowClasses
                trimmedLine = trimmed
            }
            
            trimmedLine.split(separator: "|").enumerated().forEach { index, item in
                let column = TableItemEvergreenElement(text: String(item))
                column.alignment = currentTable?.rows.first?.columns[index].alignment ?? .left
                rowElement.columns.append(column)
            }
            
            if rowElement.columns.count > (currentTable?.numColumns ?? 0) {
                currentTable?.numColumns = rowElement.columns.count
            }

            currentTable?.rows.append(rowElement)
        } else {
            let tableElement = TableEvergreenElement()
            let rowElement = TableRowEvergreenElement()

            var trimmedLine = line
            if trimmedLine.isMatching(parentIdentifierMatch) {
                let (trimmed, tableId, tableClasses) = splitIdentifiersFromLine(line: trimmedLine)
                tableElement.id = tableId
                tableElement.classes = tableClasses
                trimmedLine = trimmed
            }

            if trimmedLine.isMatching(identifierMatch) {
                let (trimmed, rowId, rowClasses) = splitIdentifiersFromLine(line: line)
                rowElement.id = rowId
                rowElement.classes = rowClasses
                trimmedLine = trimmed
            }

            trimmedLine.split(separator: "|").forEach { item in
                rowElement.columns.append(TableItemEvergreenElement(text: String(item)))
            }
            
            tableElement.numColumns = rowElement.columns.count
            tableElement.rows.append(rowElement)
            currentTable = tableElement
            inTable = true
            addToElements(tableElement)
        }
    }
    
    // MARK: <div> Element
    func parseDivElement(_ line: String) {
        var identifier = line.replacingOccurrences(of: "<<-", with: "").trim()
        let divElement = DivEvergreenElement(elementType: "div", identifier: identifier)
        
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
