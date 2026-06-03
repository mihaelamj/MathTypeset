import Foundation

/// A positioned text run produced by the layout: the neutral equivalent of a
/// PDF text run. The layout fills these in; the consumer's emitter turns each
/// one into PDF text, an SVG `<text>`/`<path>`, or MathML.
///
/// `text`, `font`, `size`, and `color` describe what to draw; `baselineOffset`
/// shifts the run vertically from the run's baseline (used for scripts).
public struct MathRun: Equatable, Sendable {
    public var text: String
    public var font: MathFontStyle
    public var size: Double
    public var color: MathColor
    public var baselineOffset: Double

    public init(
        text: String,
        font: MathFontStyle,
        size: Double,
        color: MathColor,
        baselineOffset: Double = 0,
    ) {
        self.text = text
        self.font = font
        self.size = size
        self.color = color
        self.baselineOffset = baselineOffset
    }
}
