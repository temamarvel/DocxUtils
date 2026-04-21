import Foundation

struct PlaceholderMatch {
    let fullRange: Range<String.Index>
    let key: String
}

struct DocxPlaceholderMatcher {
    let pattern: DocxPlaceholderPattern

    init(pattern: DocxPlaceholderPattern = .init()) {
        self.pattern = pattern
    }

    func findMatches(in text: String) -> [PlaceholderMatch] {
        let regex = pattern.regex
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)

        return regex.matches(in: text, options: [], range: nsRange).compactMap { match in
            guard
                match.numberOfRanges >= 2,
                let fullRange = Range(match.range(at: 0), in: text),
                let keyRange = Range(match.range(at: 1), in: text)
            else {
                return nil
            }

            return PlaceholderMatch(
                fullRange: fullRange,
                key: String(text[keyRange])
            )
        }
    }
}
