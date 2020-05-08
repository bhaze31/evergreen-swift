//
//  Evergreen+String.swift
//
//
//  Created by Brian Hasenstab on 4/20/20.
//

import Foundation

extension String {

    /// Replace all instances of `matching` in the string with `with`
    ///
    /// Use this method on any instance of a Strng to replace any matches by
    /// the regular expression with the supplied with
    ///
    /// - Parameter matching: A regular expression to find matches in the string
    /// - Parameter with: The string to replace instances of match with
    /// - Parameter options: Matching options for the regular expression
    ///
    /// - Returns: The new string with replacements

    func replaceAll(matching: NSRegularExpression, with template: String, options: NSRegularExpression.MatchingOptions = []) -> String {
        return matching.stringByReplacingMatches(in: self, options: options, range: self.fullRange(), withTemplate: template)
    }

    /// Replace first instance of `matching` in the string with `with`
    ///
    /// Use this method on any instance of a Strng to replace any matches by
    /// the regular expression with the supplied with
    ///
    /// - Parameter matching: A regular expression to find matches in the string
    /// - Parameter with: The string to replace instances of match with
    /// - Parameter options: Matching options for the regular expression
    ///
    /// - Returns: The new string with the first match, if applicable, replaced

    func replaceFirst(matching: NSRegularExpression, with template: String, options: NSRegularExpression.MatchingOptions = []) -> String {
        guard let match = matching.firstMatch(in: self, options: options, range: fullRange()) else {
            return self
        }

        return matching.stringByReplacingMatches(in: self, options: options, range: match.range, withTemplate: template)
    }

    /// Removes all instances of `matching`
    ///
    /// Use this method to remove all instances of matching within the given String
    ///
    /// - Parameter matching: A regular expression to find matches in the string
    /// - Parameter options: Matching options for the regular expression
    ///
    /// - Returns: The new string with the matching expressions removed

    func removeAll(matching: NSRegularExpression, options: NSRegularExpression.MatchingOptions = []) -> String {
        return replaceAll(matching: matching, with: "", options: options)
    }

    /// Replace matches of strings with the given replacement
    ///
    /// Used to replace multiple substrings at the same time
    ///
    /// - Parameters _: Strings to replace within the given String
    /// - Parameters with: String to replace with, defaults to ""
    ///
    /// - Returns: String with any replaced matches

    func replaceSubstrings(_ items: [String], with: String = "") -> String {
        var tempString = self

        for item in items {
            tempString = tempString.replacingOccurrences(of: item, with: "")
        }

        return tempString
    }

    /// Checks if a String has a match
    ///
    /// Use this method to determine if there is at least one match from the regular expression
    /// in the given String
    ///
    /// - Parameter _:  A regular expression to match against
    /// - Parameter in: The range to search over, defaults to the full string
    /// - Parameter options: Regular expression matching options, defaults to []
    ///
    /// - Returns: True or false depending if there was a match or not

    func isMatching(_ match: NSRegularExpression, in givenRange: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        let range = givenRange ?? fullRange()
        if let _ = match.firstMatch(in: self, options: options, range: range) {
            return true
        }

        return false
    }

    /// Returns the string from the first match
    ///
    /// Overrides the trimmingCharacters(in:) on String to default to removing whitespace
    ///
    /// - Parameter _: A regular expression to match against
    /// - Parameter in: The range to search over, defaults to the full string
    /// - Parameter options: Regular expression matching options, defaults to []
    ///
    /// - Returns: A new string with the characters replaced

    func stringFromMatch(_ regex: NSRegularExpression, in range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
        let matchRange = range ?? fullRange()
        guard let match = regex.firstMatch(in: self, options: options, range: matchRange) else {
            return ""
        }
        return String(self[Range(match.range, in: self)!])
    }

    /// Remove characters from the given set
    ///
    /// Overrides the trimmingCharacters(in:) on String to default to removing whitespace
    ///
    /// - Parameter _: Characters to remove, defaults to whitespacesAndNewLines
    ///
    /// - Returns: A new string with the characters replaced

    func trim(_ characters: CharacterSet = .whitespacesAndNewlines) -> String {
        return self.trimmingCharacters(in: characters)
    }

    /// Return an NSRange for the full length of the given string
    ///
    /// - Returns: NSRange from 0 to count of characters

    func fullRange() -> NSRange {
        return NSRange(location: 0, length: self.count)
    }
}
