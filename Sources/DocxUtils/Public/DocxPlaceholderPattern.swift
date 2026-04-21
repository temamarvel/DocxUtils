import Foundation

public struct DocxPlaceholderPattern: Sendable, Hashable {
    public let prefix: String
    public let suffix: String
    public let keyPattern: String

    public init(
        prefix: String = "<!",
        suffix: String = "!>",
        keyPattern: String = #"[A-Za-z0-9_]+"#
    ) {
        self.prefix = prefix
        self.suffix = suffix
        self.keyPattern = keyPattern
    }

    var regex: NSRegularExpression {
        let escaped = NSRegularExpression.escapedPattern(for: prefix)
        let escapedSuffix = NSRegularExpression.escapedPattern(for: suffix)
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: "\(escaped)(\(keyPattern))\(escapedSuffix)")
    }
}
