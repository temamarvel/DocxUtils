import Foundation

/// Errors that can occur during conditional block assembly of a DOCX template.
public enum DocxConditionalAssemblyError: Error, LocalizedError, Sendable {
    case malformedControlToken(String, part: String)
    case switchStartWithoutEnd(key: String, part: String)
    case switchEndWithoutStart(part: String)
    case caseStartOutsideSwitch(value: String, part: String)
    case caseEndWithoutStart(part: String)
    case caseStartWithoutEnd(value: String, part: String)
    case defaultStartOutsideSwitch(part: String)
    case defaultEndWithoutStart(part: String)
    case defaultStartWithoutEnd(part: String)
    case duplicateCaseValue(key: String, value: String, part: String)
    case duplicateDefault(part: String)
    case nestedSwitchNotSupported(part: String)
    case missingValueForSwitch(key: String, part: String)
    case noMatchingCase(key: String, value: String, part: String)

    public var errorDescription: String? {
        switch self {
        case .malformedControlToken(let token, let part):
            return "Malformed control token '\(token)' in part '\(part)'."
        case .switchStartWithoutEnd(let key, let part):
            return "<!switch_start:\(key)!> has no matching <!switch_end!> in part '\(part)'."
        case .switchEndWithoutStart(let part):
            return "<!switch_end!> found without a preceding <!switch_start!> in part '\(part)'."
        case .caseStartOutsideSwitch(let value, let part):
            return "<!case_start:\(value)!> found outside a switch block in part '\(part)'."
        case .caseEndWithoutStart(let part):
            return "<!case_end!> found without a preceding <!case_start!> in part '\(part)'."
        case .caseStartWithoutEnd(let value, let part):
            return "<!case_start:\(value)!> has no matching <!case_end!> in part '\(part)'."
        case .defaultStartOutsideSwitch(let part):
            return "<!default_start!> found outside a switch block in part '\(part)'."
        case .defaultEndWithoutStart(let part):
            return "<!default_end!> found without a preceding <!default_start!> in part '\(part)'."
        case .defaultStartWithoutEnd(let part):
            return "<!default_start!> has no matching <!default_end!> in part '\(part)'."
        case .duplicateCaseValue(let key, let value, let part):
            return "Duplicate case value '\(value)' in switch '\(key)' in part '\(part)'."
        case .duplicateDefault(let part):
            return "Multiple <!default_start!> blocks inside a single switch in part '\(part)'."
        case .nestedSwitchNotSupported(let part):
            return "Nested <!switch_start!> inside another switch block is not supported (part '\(part)')."
        case .missingValueForSwitch(let key, let part):
            return "No value provided for switch key '\(key)' in part '\(part)'."
        case .noMatchingCase(let key, let value, let part):
            return "No matching case '\(value)' for switch key '\(key)' in part '\(part)'."
        }
    }
}
