import Foundation

public enum MathLayoutElement: Equatable, Sendable {
    case text(run: MathRun, x: Double, y: Double)
    case rule(x: Double, y: Double, width: Double, height: Double, color: MathColor)

    func offsetBy(x deltaX: Double, y deltaY: Double) -> MathLayoutElement {
        switch self {
        case let .text(run, x, y):
            .text(run: run, x: x + deltaX, y: y + deltaY)
        case let .rule(x, y, width, height, color):
            .rule(x: x + deltaX, y: y + deltaY, width: width, height: height, color: color)
        }
    }
}
