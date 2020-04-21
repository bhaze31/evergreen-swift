import XCTest
@testable import Evergreen

final class EvergreenConverterTests: XCTestCase {
    func testImageConverted() {
        let imageElement = ImageEvergreenElement(elementType: "img", src: "a_source", alt: "alt_text", title: "title")
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
        let paragraphElement = TextEvergreenElement(elementType: "p", text: "A test")
        let converter = EvergreenConverter(elements: [paragraphElement])
        let result = converter.convert()
        
        XCTAssertEqual(result, "<p>A test</p>")
    }
    
    func testHeaderConverted() {
        let converter = EvergreenConverter(elements: [])
        for i in 1...6 {
            let headerElement = TextEvergreenElement(elementType: "h\(i)", text: "Header")
            converter.elements = [headerElement]
            let result = converter.convert()
            
            XCTAssertEqual(result, "<h\(i)>Header</h\(i)>")
        }
    }
    
    func testChildElementsConverted() {
        let divElement = DivEvergreenElement(elementType: "div", identifier: "DIV")
        let paragraphElement = TextEvergreenElement(elementType: "p", text: "A test")
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
        let paragraphElement = TextEvergreenElement(elementType: "p", text: "A paragraph <a!>that<!a> has at least <a!>two<!a> links.")
        let firstLinkElement = LinkEvergreenElement(text: "that", href: "a-link-1", title: "title 1")
        let secondLinkElement = LinkEvergreenElement(text: "two", href: "a-link-2")
        paragraphElement.links = [firstLinkElement, secondLinkElement]
        let converter = EvergreenConverter(elements: [paragraphElement])
        
        let result = converter.convert()
        
        let expectedResult = "<p>A paragraph <a href=\"a-link-1\" title=\"title 1\">that</a> has at least <a href=\"a-link-2\">two</a> links.</p>"

        XCTAssertEqual(result, expectedResult)
    }
    
    func testOrderedListElementConverted() {
        let listItemElement1 = ListItemEvergreenElement("Hello")
        let listItemElement2 = ListItemEvergreenElement("World")
        let orderedList = ListEvergreenElement(elementType: "ol")
        orderedList.children = [listItemElement1, listItemElement2]
        
        let converter = EvergreenConverter(elements: [orderedList])
        
        let result = converter.convert()
        
        let expectedResult = "<ol><li>Hello</li><li>World</li></ol>"

        XCTAssertEqual(result, expectedResult)
    }
    
    func testUnorderedListElementConverted() {
        let listItem1 = ListItemEvergreenElement("Hello")
        let listItem2 = ListItemEvergreenElement("World")
        let unorderedList = ListEvergreenElement(elementType: "ul")
        unorderedList.children = [listItem1, listItem2]
        
        let converter = EvergreenConverter(elements: [unorderedList])
        
        let result = converter.convert()
        
        let expectedResult = "<ul><li>Hello</li><li>World</li></ul>"

        XCTAssertEqual(result, expectedResult)
    }
    
    func testLinksInListItems() {
        let linkItem = LinkEvergreenElement(text: "here", href: "a-link", title: "title-1")
        let listItem = ListItemEvergreenElement("A link <a!>here<!a>")
        listItem.links = [linkItem]
        let orderedList = ListEvergreenElement(elementType: "ol")
        orderedList.children = [listItem]
        
        let converter = EvergreenConverter(elements: [orderedList])
        
        let result = converter.convert()
        
        let expectedResult = "<ol><li>A link <a href=\"a-link\" title=\"title-1\">here</a></li></ol>"
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testBlockquoteElementConverted() {
        let paragraphElement = TextEvergreenElement(elementType: "p", text: "A quote from a person")
        let blockquoteElement = BlockquoteEvergreenElement()
        blockquoteElement.children = [paragraphElement]
        
        let converter = EvergreenConverter(elements: [blockquoteElement])
        
        let result = converter.convert()
        
        let expectedResult = "<blockquote><p>A quote from a person</p></blockquote>"
        
        XCTAssertEqual(result, expectedResult)
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
    ]
}
