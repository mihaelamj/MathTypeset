import Foundation

/// A neutral font identity for a math run. The layout treats it as an opaque
/// token: it never reads metrics from it, it only carries it on each run so the
/// consumer's `measureText` closure and emitter can resolve a concrete font.
///
/// `fontID` lets a consumer pin the exact font artifact so the font it measures
/// against and the font it renders with are the same file (important for SVG
/// glyph-outline emitters, where on-screen geometry must match the layout).
public struct MathFontStyle: Equatable, Sendable {
    /// The math alphabet variant. Kept extensible: full TeX math has further
    /// alphabets (script, double-struck, sans-serif, fraktur) that map to extra
    /// MathML `mathvariant` values; adding cases here is non-breaking.
    public enum Variant: String, Equatable, Sendable, CaseIterable {
        case regular
        case bold
        case italic
        case boldItalic
        case monospace
    }

    public var variant: Variant

    /// Opaque consumer-defined font identifier. `nil` means the consumer's
    /// default font for the variant.
    public var fontID: String?

    public init(variant: Variant, fontID: String? = nil) {
        self.variant = variant
        self.fontID = fontID
    }

    public static let regular = MathFontStyle(variant: .regular)
    public static let bold = MathFontStyle(variant: .bold)
    public static let italic = MathFontStyle(variant: .italic)
    public static let boldItalic = MathFontStyle(variant: .boldItalic)
    public static let monospace = MathFontStyle(variant: .monospace)
}
