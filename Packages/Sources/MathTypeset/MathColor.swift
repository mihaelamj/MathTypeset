import Foundation

/// An RGB color in the `0...1` range, neutral to any rendering backend. A PDF
/// consumer maps it to its own color type; an SVG or MathML consumer maps it to
/// a CSS color.
public struct MathColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let black = MathColor(red: 0, green: 0, blue: 0)
}
