import Foundation

public indirect enum MathNode: Equatable, Sendable {
    case sequence([MathNode])
    case text(String)
    case symbol(display: String, linearized: String, isBigOperator: Bool)
    case fraction(numerator: MathNode, denominator: MathNode)
    case radical(radicand: MathNode)
    case scripts(base: MathNode, subscript: MathNode?, superscript: MathNode?)
    case accent(symbol: String, linearized: String, isOverline: Bool, base: MathNode)
    case matrix(rows: [[MathNode]], open: String, close: String, leftAlign: Bool)
    case scaledDelimiter(symbol: String, scale: Double)
}
