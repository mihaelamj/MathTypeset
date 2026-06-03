import Foundation

/// Minimal error surface used by the package's OpenType MATH table reader. Only
/// the cases the MATH path needs are defined here; consumers parsing other font
/// tables use their own error type.
enum TrueTypeFontError: Error, Equatable, LocalizedError {
    case truncated(table: String, offset: Int, needed: Int, tableLength: Int)
    case malformedTable(tag: String, reason: String)

    var errorDescription: String? {
        switch self {
        case let .truncated(table, offset, needed, tableLength):
            "The \(table) table is truncated at byte \(offset); needed \(needed) bytes in \(tableLength) bytes."
        case let .malformedTable(tag, reason):
            "The `\(tag)` table is malformed: \(reason)"
        }
    }
}
