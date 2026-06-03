import Foundation

public struct MathBox: Equatable, Sendable {
    public var width: Double
    public var height: Double
    public var depth: Double
    public var elements: [MathLayoutElement]

    public init(width: Double, height: Double, depth: Double, elements: [MathLayoutElement]) {
        self.width = width
        self.height = height
        self.depth = depth
        self.elements = elements
    }
}
