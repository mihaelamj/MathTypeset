import Foundation

public enum MathLayoutElement: Equatable, Sendable {
    case text(run: MathRun, x: Double, y: Double)
    case rule(x: Double, y: Double, width: Double, height: Double, color: MathColor)
    /// A straight stroked segment from `(x1, y1)` to `(x2, y2)` of the given
    /// thickness, in the same baseline-relative, +y-up space as the other
    /// elements. Used for shapes a rule cannot express, such as the diagonal
    /// strokes of a radical sign that scale with their radicand.
    case line(x1: Double, y1: Double, x2: Double, y2: Double, thickness: Double, color: MathColor)

    func offsetBy(x deltaX: Double, y deltaY: Double) -> MathLayoutElement {
        switch self {
        case let .text(run, x, y):
            .text(run: run, x: x + deltaX, y: y + deltaY)
        case let .rule(x, y, width, height, color):
            .rule(x: x + deltaX, y: y + deltaY, width: width, height: height, color: color)
        case let .line(x1, y1, x2, y2, thickness, color):
            .line(x1: x1 + deltaX, y1: y1 + deltaY, x2: x2 + deltaX, y2: y2 + deltaY, thickness: thickness, color: color)
        }
    }
}
