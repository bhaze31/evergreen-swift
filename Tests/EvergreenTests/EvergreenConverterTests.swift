import XCTest
@testable import Evergreen

final class EvergreenConverterTests: XCTestCase {
    func testImageConverted() {
        let imageElement = EvergreenElement(elementType: "img", src: "a_source", linkText: "alt_text", linkAlt: "title")
        let converter = EvergreenConverter(elements: [imageElement])
        let result = converter.convert()
        
        XCTAssertEqual(result, "<img src=\"a_source\" alt=\"alt_text\" title=\"title\" />")
    }
    
    func testHorizontalRuleConverted() {
        let horizontalRuleElement = EvergreenElement(elementType: "hr")
        let converter = EvergreenConverter(elements: [horizontalRuleElement])
        let result = converter.convert()
        
        XCTAssertEqual(result, "<hr />")
    }
    
    func testParagraphConverted() {
        let paragraphElement = EvergreenElement(elementType: "p", text: "A test")
        let converter = EvergreenConverter(elements: [paragraphElement])
        var result = converter.convert()
        
        XCTAssertEqual(result, "<p>A test</p>")
        
        let paragraphWithIdentifiers = EvergreenElement(elementType: "p", text: "An id test")
        paragraphWithIdentifiers.id = "test"
        converter.updateElements(elements: [paragraphWithIdentifiers])
        result = converter.convert()
        
        XCTAssertEqual(result, "<p id=\"test\">An id test</p>")
        
        paragraphWithIdentifiers.classes = ["c1", "c2"]
        converter.updateElements(elements: [paragraphWithIdentifiers])
        result = converter.convert()

        XCTAssertEqual(result, "<p class=\"c1 c2\" id=\"test\">An id test</p>")
        
        paragraphWithIdentifiers.id = nil
        converter.updateElements(elements: [paragraphWithIdentifiers])
        result = converter.convert()
        
        XCTAssertEqual(result, "<p class=\"c1 c2\">An id test</p>")
    }
    
    func testHeaderConverted() {
        let converter = EvergreenConverter(elements: [])
        for i in 1...6 {
            let headerElement = EvergreenElement(elementType: "h\(i)", text: "Header")
            converter.elements = [headerElement]
            let result = converter.convert()
            
            XCTAssertEqual(result, "<h\(i)>Header</h\(i)>")
        }
    }
    
    func testChildElementsConverted() {
        let divElement = EvergreenElement(elementType: "div", divIdentifier: "DIV")
        let paragraphElement = EvergreenElement(elementType: "p", text: "A test")
        divElement.children = [paragraphElement]
        let converter = EvergreenConverter(elements: [divElement])
        let result = converter.convert()
        
        XCTAssertEqual(result, "<div><p>A test</p></div>")
    }
    
    func testBreakElementConverted() {
        let breakElement = EvergreenElement(elementType: "br")
        let converter = EvergreenConverter(elements: [breakElement])
        let result = converter.convert()
        
        XCTAssertEqual(result, "<br />")
    }
    
    func testLinkElementConverted() {
        let paragraphElement = EvergreenElement(elementType: "p", text: "A paragraph abcdef has at least zyxwvut links.")
        let firstLinkElement = EvergreenElement(elementType: "a", src: "a-link-1", linkText: "that", linkAlt: "title 1")
        firstLinkElement.identifier = "abcdef"
        let secondLinkElement = EvergreenElement(elementType: "a", src: "a-link-2", linkText: "two", linkAlt: nil)
        secondLinkElement.identifier = "zyxwvut"
        paragraphElement.children = [firstLinkElement, secondLinkElement]
        let converter = EvergreenConverter(elements: [paragraphElement])
        
        let result = converter.convert()
        
        let expectedResult = "<p>A paragraph <a href=\"a-link-1\" title=\"title 1\">that</a> has at least <a href=\"a-link-2\">two</a> links.</p>"
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testOrderedListElementConverted() {
        let listItemElement1 = EvergreenElement(elementType: "li", text: "Hello")
        let listItemElement2 = EvergreenElement(elementType: "li", text: "World")
        let orderedList = EvergreenElement(elementType: "ol")
        orderedList.children = [listItemElement1, listItemElement2]
        
        let converter = EvergreenConverter(elements: [orderedList])
        
        let result = converter.convert()
        
        let expectedResult = "<ol><li>Hello</li><li>World</li></ol>"

        XCTAssertEqual(result, expectedResult)
    }
    
    func testUnorderedListElementConverted() {
        let listItem1 = EvergreenElement(elementType: "li", text: "Hello")
        let listItem2 = EvergreenElement(elementType: "li", text: "World")
        let unorderedList = EvergreenElement(elementType: "ul")
        unorderedList.children = [listItem1, listItem2]
        
        let converter = EvergreenConverter(elements: [unorderedList])
        
        let result = converter.convert()
        
        let expectedResult = "<ul><li>Hello</li><li>World</li></ul>"

        XCTAssertEqual(result, expectedResult)
    }
    
    func testLinksInListItems() {
        let linkItem = EvergreenElement(elementType: "a", src: "a-link", linkText: "here", linkAlt: "title-1")
        linkItem.identifier = "abcdefg"
        let listItem = EvergreenElement(elementType: "li", text: "A link abcdefg")
        listItem.children = [linkItem]
        let orderedList = EvergreenElement(elementType: "ol")
        orderedList.children = [listItem]
        
        let converter = EvergreenConverter(elements: [orderedList])
        
        let result = converter.convert()
        
        let expectedResult = "<ol><li>A link <a href=\"a-link\" title=\"title-1\">here</a></li></ol>"
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testBlockquoteElementConverted() {
        let paragraphElement = EvergreenElement(elementType: "p", text: "A quote from a person")
        let blockquoteElement = EvergreenElement(elementType: "blockquote")
        blockquoteElement.children = [paragraphElement]
        
        let converter = EvergreenConverter(elements: [blockquoteElement])
        
        let result = converter.convert()
        
        let expectedResult = "<blockquote><p>A quote from a person</p></blockquote>"
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testTableElementConverted() {
        let tableHeader = "|a|kitchen|table|{#id .class} {{#parent .parentClass}}"
        let tableDashes = "|:---|:---:|---:|"
        let tableData = "|in|the|bedroom|{#dataID .dataClass}"
        
        let processor = EvergreenProcessor(lines: [tableHeader, tableDashes, tableData])
        
        let elements = processor.parse()
        
        let converter = EvergreenConverter(elements: elements)
        let result = converter.convert()
        XCTAssertEqual(result, "<table class=\"parentClass\" id=\"parent\"><tr class=\"class\" id=\"id\"><th style=\"text-align:left;\">a</td><th style=\"text-align:center;\">kitchen</td><th style=\"text-align:right;\">table</td></tr><tr class=\"dataClass\" id=\"dataID\"><td style=\"text-align:left;\">in</td><td style=\"text-align:center;\">the</td><td style=\"text-align:right;\">bedroom</td></tr></table>")
    }
    
    func testCodeConverted() {
        let lines: Array<String> = [
            "```",
            "function hello() {",
            "  return \"Hello World!\"",
            "}",
            "```"
        ];
        
        let processor = EvergreenProcessor(lines: lines)
        let elements = processor.parse()
        
        let converter = EvergreenConverter(elements: elements)
        let result = converter.convert()
        XCTAssertEqual(result, "<pre><code>function hello() {\n  return \"Hello World!\"\n}</code></pre>")
    }
    
    func testHeaderIDs() {
        let elements = [
            EvergreenElement(elementType: "h1", text: "Test 123!"),
            EvergreenElement(elementType: "h1", text: "And S P A C E S. Period."),
            EvergreenElement(elementType: "h2", text: "No ID")
        ]
        
        let converter = EvergreenConverter(elements: elements)
        let result = converter.convert(markHeaders: true)
        XCTAssertEqual(result, "<h1 id=\"test123\">Test 123!</h1>\n<h1 id=\"andspacesperiod\">And S P A C E S. Period.</h1>\n<h2>No ID</h2>")
    }

    static var allTests = [
        ("testImageConverter", testImageConverted),
        ("testHorizontalRuleConverter", testHorizontalRuleConverted),
        ("testParagraphConverter", testParagraphConverted),
        ("testHeaderConverter", testHeaderConverted),
        ("testChildElementsConverter", testChildElementsConverted),
        ("testBreakElementConverter", testBreakElementConverted),
        ("testLinkElementConverter", testLinkElementConverted),
        ("testOrderedListElementConverter", testOrderedListElementConverted),
        ("testBlockquoteElementConverter", testBlockquoteElementConverted),
        ("testCodeConverter", testCodeConverted),
        ("testHeaderIDs", testHeaderIDs)
    ]
}
