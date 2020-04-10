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
        let divElement = EvergreenElement(elementType: "div")
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

    static var allTests = [
        ("testImageConverter", testImageConverted),
        ("testHorizontalRuleConverter", testHorizontalRuleConverted),
        ("testParagraphConverter", testParagraphConverted),
        ("testHeaderConverter", testHeaderConverted),
        ("testChildElementsConverter", testChildElementsConverted),
        ("testBreakElementConverrter", testBreakElementConverted)
    ]
}
