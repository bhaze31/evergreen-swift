import Foundation
import XCTest
@testable import Evergreen

final class StringExtensionTests: XCTestCase {
    func testReplaceAllMethod() {
        let str = "replace replace none replace"
        let match = try! NSRegularExpression(pattern: "replace", options: [])
        
        let replaced = str.replaceAll(matching: match, with: "_")
        
        XCTAssertEqual(replaced, "_ _ none _")
    }
    
    func testReplaceFirstMethod() {
        let str = "replace replace none replace"
        let match = try! NSRegularExpression(pattern: "replace", options: [])
        
        let replaced = str.replaceFirst(matching: match, with: "_")
        
        XCTAssertEqual(replaced, "_ replace none replace")
    }
    
    func testReplaceFirstMethodWithMissingRegex() {
        let str = "replace replace none replace"
        let match = try! NSRegularExpression(pattern: "missing", options: [])
        
        let replaced = str.replaceFirst(matching: match, with: "_")
        
        XCTAssertEqual(replaced, "replace replace none replace")
    }
    
    func testReplaceFirstWithPassedRange() {
        let str = "replace replace none replace"
        let match = try! NSRegularExpression(pattern: "replace", options: [])
        
        let range = match.firstMatch(in: str, options: [], range: str.fullRange())?.range
        
        let replaced = str.replaceFirst(matching: match, with: "_", in: range)
        
        XCTAssertEqual(replaced, "_ replace none replace")
    }
    
    func testStringFromMatchWithPassedRange() {
        let str = "replace replace none replace"

        let match = try! NSRegularExpression(pattern: "replace", options: [])

        let range = match.firstMatch(in: str, options: [], range: str.fullRange())?.range
        
        let badMatch = try! NSRegularExpression(pattern: "none", options: [])
        
        let result = str.stringFromMatch(badMatch, in: range)
        
        XCTAssertEqual(result, "")
    }
    
    func testReplaceRangeWithPassedRange() {
        var str = "replace replace none replace"
        
        let match = try! NSRegularExpression(pattern: "replace", options: [])
        
        let range = match.firstMatch(in: str, options: [], range: str.fullRange())?.range
        
        let badMatch = try! NSRegularExpression(pattern: "none", options: [])
        
        str.replaceRange(matching: badMatch, with: "nothing", options: [], range: range)
        
        XCTAssertEqual(str, "replace replace none replace")
    }

    static var allTests = [
        "testReplaceAll",
        "testReplaceFirstMethod",
        "testReplaceFirstMethodWithMissingRegex",
        "testReplaceFirstWithPassedRange",
        "testStringFromMatchWithPassedRange",
        "testReplaceRangeWithPassedRange"
    ]
}
