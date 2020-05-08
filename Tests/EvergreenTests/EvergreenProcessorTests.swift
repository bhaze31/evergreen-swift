import XCTest
@testable import Evergreen

final class EvergreenProcessorTests: XCTestCase {
    
    func checkClasses(expected: [String], classes: [String]) {
        XCTAssertEqual(expected.count, classes.count)

        expected.forEach { item in
            let index = classes.firstIndex(of: item)
            XCTAssertNotNil(index, "Testing: \(item)")
            
        }
    }

    func testHeaderProcessed() {
        let processor = EvergreenProcessor(lines: [])
        for i in 1...6 {
            var header = ""
            for _ in 1...i {
                header += "#"
            }
            
            header += " A header ###"
            
            processor.updateLines(lines: [header])
            
            let elements = processor.parse()
            let textElement = elements.first as! TextEvergreenElement
            
            XCTAssertEqual(textElement.text, "A header ###")
            XCTAssertEqual(textElement.elementType, "h\(i)")
        }
        
        let headerWithID = "# Hello Old Friend {#clapton}"
        processor.updateLines(lines: [headerWithID])
        
        var elements = processor.parse()
        var textElement = elements.first as! TextEvergreenElement
        
        XCTAssertEqual(textElement.text, "Hello Old Friend")
        XCTAssertEqual(textElement.id, "clapton")
        
        let headerWithClasses = "# Riding with the King {.clapton .bb}"
        processor.updateLines(lines: [headerWithClasses])
        
        elements = processor.parse()
        textElement = elements.first as! TextEvergreenElement
        
        XCTAssertEqual(textElement.text, "Riding with the King")
        checkClasses(expected: ["clapton", "bb"], classes: textElement.classes)
        
        let headerWithIdAndClasses = "# Layla {.clapton .derek #blues}"
        processor.updateLines(lines: [headerWithIdAndClasses])
        
        elements = processor.parse()
        textElement = elements.first as! TextEvergreenElement
        
        XCTAssertEqual(textElement.text, "Layla")
        XCTAssertEqual(textElement.id, "blues")
        checkClasses(expected: ["clapton", "derek"], classes: textElement.classes)
    }
    
    func testParagraphProcessed() {
        let paragraph = "A paragraph"
        let paragraphWithID = "Another paragraph {#with_id}"
        let paragraphWithClasses = "A third paragraph {.classy .list}"
        let paragraphWithIDAndClasses = "A last paragraph {.whats .happenin #baskins}"
        
        let processor = EvergreenProcessor(lines: [paragraph, paragraphWithID, paragraphWithClasses, paragraphWithIDAndClasses])
        let elements = processor.parse()
        let element = elements.first
        
        var textElement = element as! TextEvergreenElement
        
        XCTAssertEqual(textElement.text, paragraph)
        XCTAssertEqual(textElement.elementType, "p")
        XCTAssertEqual(textElement.id, nil)
        
        textElement = elements[1] as! TextEvergreenElement
        XCTAssertEqual(textElement.text, "Another paragraph")
        XCTAssertEqual(textElement.elementType, "p")
        XCTAssertEqual(textElement.id, "with_id")
        
        textElement = elements[2] as! TextEvergreenElement
        XCTAssertEqual(textElement.text, "A third paragraph")
        XCTAssertEqual(textElement.elementType, "p")
        XCTAssertEqual(textElement.id, nil)
        checkClasses(expected: ["classy", "list"], classes: textElement.classes)
        
        textElement = elements[3] as! TextEvergreenElement
        XCTAssertEqual(textElement.text, "A last paragraph")
        XCTAssertEqual(textElement.elementType, "p")
        XCTAssertEqual(textElement.id, "baskins")
        checkClasses(expected: ["whats", "happenin"], classes: textElement.classes)
    }
    
    func testLinkInParagraphProcessed() {
        let paragraphWithLinks = "A paragraph [that](title two links) has at least [two](reffin) links."
        
        let processor = EvergreenProcessor(lines: paragraphWithLinks)
        let elements = processor.parse()
        
        let element = elements.first as! TextEvergreenElement
        
        XCTAssertEqual(element.text, "A paragraph <a!>that<!a> has at least <a!>two<!a> links.")
        XCTAssertEqual(element.links.count, 2)
        
        let firstLink = element.links.first!
        let secondLink = element.links.last!
        
        XCTAssertEqual(firstLink.text, "that")
        XCTAssertEqual(firstLink.href, "title")
        XCTAssertEqual(firstLink.title, "two links")
        
        XCTAssertEqual(secondLink.text, "two")
        XCTAssertEqual(secondLink.href, "reffin")
        XCTAssertEqual(secondLink.title, nil)
    }
    
    func testImageProcessed() {
        let image = "![Alt Image](source and a title)"
        let titleLessImage = "![Alt Image](source)"
        let processor = EvergreenProcessor(lines: [image, titleLessImage])
        let elements = processor.parse()
        var element = elements.first

        let imageElement = element as! ImageEvergreenElement
        
        XCTAssertEqual(imageElement.alt, "Alt Image")
        XCTAssertEqual(imageElement.src, "source")
        XCTAssertEqual(imageElement.title, "and a title")

        element = elements.last
        
        let titleLessImageElement = element as! ImageEvergreenElement
        
        XCTAssertEqual(titleLessImageElement.alt, "Alt Image")
        XCTAssertEqual(titleLessImageElement.src, "source")
        XCTAssertEqual(titleLessImageElement.title, nil)
    }
    
    func testBreakProcessed() {
        let breakString = "  "
        let processor = EvergreenProcessor(lines: breakString)
        
        let elements = processor.parse()
        let element = elements.first
        
        XCTAssertEqual(element?.elementType, "br")
    }
    
    func testHorizontalRuleProcessed() {
        let hr1 = "***"
        let hr2 = "---"
        let hr3 = "___"
        
        let processor = EvergreenProcessor(lines: [hr1, hr2, hr3])
        
        var elements = processor.parse()
        
        elements.forEach { element in
            XCTAssertEqual(element.elementType, "hr")
        }
        
        processor.lines = ["*-*"]
        
        elements = processor.parse()
        let element = elements.first!
        
        XCTAssertEqual(element.elementType, "ul")
    }
    
    func testOrderedListProcessed() {
        let listItem1 = "1. Hello {#Item .class .classes .classed} {{#List .outerClass}}"
        let listItem2 = "1. Wow"
        
        let processor = EvergreenProcessor(lines: [listItem1, listItem2])
        
        let elements = processor.parse()

        XCTAssertEqual(elements.count, 1)
            
        let element = elements.first as! ListEvergreenElement
        
        XCTAssertEqual(element.id, "List")
        checkClasses(expected: ["outerClass"], classes: element.classes)
        
        let children = element.children

        XCTAssertEqual(element.elementType, "ol")
        XCTAssertEqual(children.count, 2)
        
        let firstItem = children.first as! ListItemEvergreenElement

        XCTAssertEqual(firstItem.id, "Item")
        XCTAssertEqual(firstItem.text, "Hello")
        checkClasses(expected: ["class", "classes", "classed"], classes: firstItem.classes)
    }
    
    func testUnOrderedListProcessed() {
        let listItem1 = "* HELLO"
        let listItem2 = "+ TO DA"
        let listItem3 = "- WORLD"
        
        let processor = EvergreenProcessor(lines: [listItem1, listItem2, listItem3])
        
        let elements = processor.parse()
        
        XCTAssertEqual(elements.count, 1)
        
        let element = elements.first as! ListEvergreenElement
        let children = element.children
        
        XCTAssertEqual(element.elementType, "ul")
        XCTAssertEqual(children.count, 3)
    }
    
    func testSubListsProcessed() {
        func assertListItems(_ items: [EvergreenElement]) {
            items.forEach { item in
                XCTAssertEqual(item.elementType, "li")
            }
        }
        
        let line1 = "1. Hello"
        let line2 = "  * Subber"
        let line3 = "  * Subber 2"
        let line4 = "    1. Sub sub"
        let line5 = "  * Unsubbed"
        let line6 = "2. Second one"
        let line7 = "3. Third one"
        
        let processor = EvergreenProcessor(lines: [line1, line2, line3, line4, line5, line6, line7])
        
        let elements = processor.parse()
        
        XCTAssertEqual(elements.count, 1)
        
        let element = elements.first as! ListEvergreenElement
        let children = element.children
        
        XCTAssertEqual(element.elementType, "ol")
        XCTAssertEqual(children.count, 3)
        
        assertListItems(children)
        
        let firstItem = children.first!
        
        XCTAssertEqual(firstItem.children.count, 1)
        
        let firstSubList = firstItem.children.first!
        
        XCTAssertEqual(firstSubList.elementType, "ul")
        XCTAssertEqual(firstSubList.children.count, 3)
        
        assertListItems(firstSubList.children)
        
        let subSubList = firstSubList.children[1].children[0]
        
        XCTAssertEqual(subSubList.elementType, "ol")
        XCTAssertEqual(subSubList.children.count, 1)
        
        assertListItems(subSubList.children)
    }
    
    func testLinksInListsProcessed() {
        let line1 = "1. A link [here](linkHref title)"
        let line2 = "2. No links"
        
        let processor = EvergreenProcessor(lines: [line1, line2])
        
        let elements = processor.parse()
        
        let element = elements.first as! ListEvergreenElement
        let children = element.children

        XCTAssertEqual(element.elementType, "ol")
        XCTAssertEqual(children.count, 2)
        
        let linkElement = children.first as! ListItemEvergreenElement
        
        XCTAssertEqual(linkElement.links.count, 1)
        XCTAssertEqual(linkElement.text, "A link <a!>here<!a>")
    }
    
    func testBlockquoteProcessed() {
        let quote = "> Alls well that ends well"
        let processer = EvergreenProcessor(lines: quote)
        let elements = processer.parse()
        
        let element = elements.first!
        
        XCTAssertEqual(element.elementType, "blockquote")
    }

    func testSubBlockquoteProcessed() {
        let quote1 = "> There once was a man from peru"
        let quote2 = ">> Who dreamed he was eating his shoe"
        let quote3 = ">>> He woke with a fright"
        let quoteBreak = ">>>"
        let quote4 = ">>> In the middle of the night"
        let quote5 = "> To see that his dream had come true"
        let processor = EvergreenProcessor(lines: [quote1, quote2, quote3, quoteBreak, quote4, quote5])
        let elements = processor.parse()
        
        XCTAssertEqual(elements.count, 1)
        
        let blockQuote = elements.first as! BlockquoteEvergreenElement
        XCTAssertEqual(blockQuote.elementType, "blockquote")
        XCTAssertEqual(blockQuote.children.count, 3)
        XCTAssertEqual(blockQuote.children.first?.elementType, "p")
        XCTAssertEqual(blockQuote.children.last?.elementType, "p")

        let subBlockquote = blockQuote.children[1] as! BlockquoteEvergreenElement
        XCTAssertEqual(subBlockquote.elementType, "blockquote")
        XCTAssertEqual(subBlockquote.children.count, 2)
        
        let subSubBlockquote = subBlockquote.children.last as! BlockquoteEvergreenElement
        XCTAssertEqual(subSubBlockquote.children.count, 2)
    }
    
    func testBlockquotesWithIDs() {
        let quote1 = "> There once was a man from peru {#title1 .count .of .items} {{#blockquote1 .base_case}}"
        let quote2 = ">> Who dreamed he was eating his shoe"
        let quote3 = ">>> He woke with a fright {#subtitle .subliminal} {{#splitted .message}}"
        let quoteBreak = ">>> {{#remaining .valued}}"
        let quote4 = ">>> In the middle of the night"
        let quote5 = "> To see that his dream had come true {{#bad_id .not_valued}}"
        let processor = EvergreenProcessor(lines: [quote1, quote2, quote3, quoteBreak, quote4, quote5])
        let elements = processor.parse()
        
        XCTAssertEqual(elements.count, 1)
        
        let blockQuote = elements.first as! BlockquoteEvergreenElement
        XCTAssertEqual(blockQuote.elementType, "blockquote")
        XCTAssertEqual(blockQuote.id, "blockquote1")
        checkClasses(expected: ["base_case"], classes: blockQuote.classes)
        
        XCTAssertEqual(blockQuote.children.count, 3)
        XCTAssertEqual(blockQuote.children.first?.elementType, "p")
        XCTAssertEqual(blockQuote.children.first?.id, "title1")
        checkClasses(expected: ["count", "of", "items"], classes: blockQuote.children.first!.classes)
        
        
        let finalElement = blockQuote.children.last as! TextEvergreenElement
        XCTAssertEqual(finalElement.elementType, "p")
        XCTAssertEqual(finalElement.id, nil)
        XCTAssertEqual(finalElement.text, "To see that his dream had come true {{#bad_id .not_valued}}")
        
        let subBlockquote = blockQuote.children[1] as! BlockquoteEvergreenElement
        XCTAssertEqual(subBlockquote.elementType, "blockquote")
        XCTAssertEqual(subBlockquote.children.count, 2)
        
        let subSubBlockquote = subBlockquote.children.last as! BlockquoteEvergreenElement
        // Since we do not parse #|>> remaining, it should be one paragraph
        XCTAssertEqual(subSubBlockquote.children.count, 1)
        XCTAssertEqual(subSubBlockquote.id, "splitted")
        checkClasses(expected: ["message"], classes: subSubBlockquote.classes)

        XCTAssertEqual(subSubBlockquote.children.first?.id, "subtitle")
        checkClasses(expected: ["subliminal"], classes: subSubBlockquote.children.first!.classes)
    }
    
    func testDivProcessed() {
        let divOpen = "<<-DIV"
        let data = "In a div"
        let divClose = "<<-DIV"
        
        let processor = EvergreenProcessor(lines: [divOpen, data, divClose])
        
        let elements = processor.parse()
        
        let divElement = elements.first as! DivEvergreenElement
        
        XCTAssertEqual(divElement.elementType, "div")
        XCTAssertEqual(divElement.identifier, "DIV")
        XCTAssertEqual(divElement.children.count, 1)
        XCTAssertEqual(divElement.children.first?.elementType, "p")
    }
    
    func testDivWithIDProcessed() {
        let divOpen = "<<- DIV {#main .tribal}"
        let data = "In a div with an ID"
        let divClass = "<<-DIV"
        
        let processor = EvergreenProcessor(lines: [divOpen, data, divClass])
        
        let elements = processor.parse()
        
        let divElement = elements.first as! DivEvergreenElement
        
        XCTAssertEqual(divElement.elementType, "div")
        XCTAssertEqual(divElement.identifier, "DIV")
        XCTAssertEqual(divElement.id, "main")
        checkClasses(expected: ["tribal"], classes: divElement.classes)
    }
    
    func testSubDivProcessed() {
        let divOpen = "<<-DIV"
        let subDivOpen = "<<-SUB"
        let subData = "In a sub div"
        let subDivClose = "<<-SUB"
        let data = "In a sub"
        let divClose = "<<-DIV"
        
        let processor = EvergreenProcessor(lines: [divOpen, subDivOpen, subData, subDivClose, data, divClose])
        
        let elements = processor.parse()
        
        let divElement = elements.first as! DivEvergreenElement
        
        XCTAssertEqual(divElement.elementType, "div")
        XCTAssertEqual(divElement.identifier, "DIV")
        
        XCTAssertEqual(divElement.children.count, 2)
        XCTAssertEqual(divElement.children.last?.elementType, "p")
        
        let subDiv = divElement.children.first as! DivEvergreenElement
        XCTAssertEqual(subDiv.identifier, "SUB")
        XCTAssertEqual(subDiv.children.count, 1)
    }

    func testTableProcessed() {
        let tableHeader = "|a|kitchen|table|{#id .class}"
        let tableDashes = "|:---|:---:|---:|"
        let tableData = "|in|the|bedroom|"
        
        let processor = EvergreenProcessor(lines: [tableHeader, tableDashes, tableData])
        
        let elements = processor.parse()
        let table = elements.first as! TableEvergreenElement
        XCTAssertEqual(table.rows.count, 2)
        XCTAssertEqual(table.numColumns, 3)
        
        let headerRow = table.rows.first!
        headerRow.columns.forEach { column in
            XCTAssertEqual(column.elementType, "th")
        }
        
        let dataRow = table.rows.last!
        dataRow.columns.forEach { column in
            XCTAssertEqual(column.elementType, "td")
        }
        
        let alignments: [TableAlignment] = [.left, .center, .right]
        
        alignments.enumerated().forEach { index, alignment in
            XCTAssertEqual(headerRow.columns[index].alignment, alignment)
        }
        
        alignments.enumerated().forEach { index, alignment in
            XCTAssertEqual(dataRow.columns[index].alignment, alignment)
        }
    }

    static var allTests = [
        ("testHeaderProcessor", testHeaderProcessed),
        ("testParagraphProcessor", testParagraphProcessed),
        ("testImageProcessor", testImageProcessed),
        ("testBreakProcessor", testBreakProcessed),
        ("testHorizontalRuleProcessor", testHorizontalRuleProcessed),
        ("testOrderedListProcessor", testOrderedListProcessed),
        ("testUnOrderedListProcessor", testUnOrderedListProcessed),
        ("testSubListsProcessor", testSubListsProcessed),
        ("testLinksInListsProcessor", testLinksInListsProcessed),
        ("testBlockquoteProcessor", testBlockquoteProcessed),
        ("testSubBlockquoteProcessor", testSubBlockquoteProcessed),
        ("testDivProcessor", testDivProcessed),
        ("testDivWithIDProcessor", testDivWithIDProcessed),
        ("testSubDivProcessor", testSubDivProcessed),
        ("textTableProcessor", testTableProcessed)
    ]
}
