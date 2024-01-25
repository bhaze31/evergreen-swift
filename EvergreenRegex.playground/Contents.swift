import Cocoa

extension String {
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
    func isMatching(_ match: NSRegularExpression, in givenRange: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        let range = givenRange ?? fullRange
        if let _ = match.firstMatch(in: self, options: options, range: range) {
            return true
        }

        return false
    }
    func trim(_ characters: CharacterSet = .whitespacesAndNewlines) -> String {
        return self.trimmingCharacters(in: characters)
    }
}
let codeWithClass = try! NSRegularExpression(pattern: "^```:[a-zA-Z]+$", options: [])

let line = "```:swift"
if let match = codeWithClass.firstMatch(in: line, range: line.fullRange) {
    print(match)
} else {
    print("Cannot find a match")
}

var authorAndEmailMatch = try! NSRegularExpression(pattern: "[a-zA-Z0-9 ]*<[a-zA-Z0-9_\\-.+]*@[a-zA-Z0-9\\-.]*\\.[a-zA-Z]{2,}>")

let author = "Brian Hasenstab <bhaze2263@gmail.com>"

if author.isMatching(authorAndEmailMatch) {
    let parts = author.components(separatedBy: "<")
    let name = parts.first!.trim()
    let email = String(parts.last!.trim().dropLast())
    print(name)
    print(email)
    print("Hello world")
}

let parts = "author: hello :donkey".split(separator: ":", maxSplits: 1)
print(parts)
