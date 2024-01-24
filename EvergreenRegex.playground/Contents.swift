import Cocoa

extension String {
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}
let codeWithClass = try! NSRegularExpression(pattern: "^```:[a-zA-Z]+$", options: [])

let line = "```:swift"
if let match = codeWithClass.firstMatch(in: line, range: line.fullRange) {
    print(match)
} else {
    print("Cannot find a match")
}

