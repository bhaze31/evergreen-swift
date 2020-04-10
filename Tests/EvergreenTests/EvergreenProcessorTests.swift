import XCTest
@testable import Evergreen

final class EvergreenProcessorTests: XCTestCase {
    func testHeaderProcessed() {
        for i in 1...6 {
            var header = ""
            for _ in 1...i {
                header += "#"
            }
            
            header += " A header ###"
            
            let processor = EvergreenProcessor(lines: header)
            
            let elements: Elements = processor.parse()
            let element = elements.first!
            let textElement = element as! TextEvergreenElement

            XCTAssertEqual(textElement.text, "A header ###")
            XCTAssertEqual(textElement.elementType, "h\(i)")
        }
    }
    
    func testParagraphProcessed() {
        let paragraph = "A paragraph"
        
        let processor = EvergreenProcessor(lines: paragraph)
        let elements: Elements = processor.parse()
        let element = elements.first
        
        let textElement = element as! TextEvergreenElement
        
        XCTAssertEqual(textElement.text, paragraph)
        XCTAssertEqual(textElement.elementType, "p")
    }
    
    func testLinkInParagraphProcessed() {
        let paragraphWithLinks = "A paragraph [that](title two links) has at least [two](reffin) links."
        
        let processor = EvergreenProcessor(lines: paragraphWithLinks)
        let elements: Elements = processor.parse()
        
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
        let elements: Elements = processor.parse()
        var element = elements.first

        let imageElement = element as! ImageEvergreenElement
        
        XCTAssertEqual(imageElement.alt, "Alt Image")
        XCTAssertEqual(imageElement.src, "source")
        XCTAssertEqual(imageElement.title, "and a title")

        element = elements.last
        
        let titleLessImageElement = element as! ImageEvergreenElement
        
        XCTAssertEqual(titleLessImageElement.alt, "Alt Image")
        XCTAssertEqual(titleLessImageElement.src, "source")
        XCTAssertEqual(titleLessImageElement.title, "")
    }
    
    func testBreakProcessed() {
        let breakString = "  "
        let processor = EvergreenProcessor(lines: breakString)
        
        let elements: Elements = processor.parse()
        let element = elements.first
        
        XCTAssertEqual(element?.elementType, "br")
    }
    
    func testHorizontalRuleProcessed() {
        let hr1 = "***"
        let hr2 = "---"
        let hr3 = "___"
        
        let processor = EvergreenProcessor(lines: [hr1, hr2, hr3])
        
        var elements: Elements = processor.parse()
        
        elements.forEach { element in
            XCTAssertEqual(element.elementType, "hr")
        }
        
        processor.lines = ["*-*"]
        
        elements = processor.parse()
        let element = elements.first!
        
        XCTAssertEqual(element.elementType, "ul")
    }
    
    func testOrderedListProcessed() {
        let listItem1 = "1. Hello"
        let listItem2 = "1. Wow"
        
        let processor = EvergreenProcessor(lines: [listItem1, listItem2])
        
        let elements: Elements = processor.parse()

        XCTAssertEqual(elements.count, 1)
            
        let element = elements.first as! ListEvergreenElement
        let children = element.children
        
        XCTAssertEqual(element.elementType, "ol")
        XCTAssertEqual(children.count, 2)
    }
    
    func testUnOrderedListProcessed() {
        let listItem1 = "* HELLO"
        let listItem2 = "+ TO DA"
        let listItem3 = "- WORLD"
        
        let processor = EvergreenProcessor(lines: [listItem1, listItem2, listItem3])
        
        let elements: Elements = processor.parse()
        
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
        
        let elements: Elements = processor.parse()
        
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
    
    func testBlockquoteProcessed() {
        let quote = "> Alls well that ends well"
        let processer = EvergreenProcessor(lines: quote)
        let elements: Elements = processer.parse()
        
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
        let elements: Elements = processor.parse()
        
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

    static var allTests = [
        ("testHeaderProcessor", testHeaderProcessed),
        ("testParagraphProcessor", testParagraphProcessed),
        ("testImageProcessor", testImageProcessed),
        ("testBreakProcessor", testBreakProcessed),
        ("testHorizontalRuleProcessor", testHorizontalRuleProcessed),
        ("testOrderedListProcessor", testOrderedListProcessed),
        ("testUnOrderedListProcessor", testUnOrderedListProcessed),
        ("testSubListsProcessor", testSubListsProcessed),
        ("testBlockquoteProcessor", testBlockquoteProcessed),
        ("testSubBlockquoteProcessor", testSubBlockquoteProcessed),
        ("testDivProcessor", testDivProcessed),
        ("testSubDivProcessor", testSubDivProcessed)
    ]
}
