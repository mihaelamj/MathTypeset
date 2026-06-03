import Foundation

public struct MathLayout {
    public var font: MathFontStyle
    public var color: MathColor
    public var measureText: (MathRun) throws -> Double
    public var metrics: MathLayoutMetrics

    public init(
        font: MathFontStyle,
        color: MathColor,
        measureText: @escaping (MathRun) throws -> Double,
        metrics: MathLayoutMetrics = .default,
    ) {
        self.font = font
        self.color = color
        self.measureText = measureText
        self.metrics = metrics
    }

    public func layout(
        _ node: MathNode,
        size: Double,
        displayStyle: Bool,
    ) throws -> MathBox {
        switch node {
        case let .sequence(children):
            try layoutSequence(children, size: size, displayStyle: displayStyle)
        case let .text(text):
            try layoutText(text, size: size)
        case let .symbol(display, _, _):
            try layoutText(display, size: size)
        case let .fraction(numerator, denominator):
            try layoutFraction(
                numerator: numerator,
                denominator: denominator,
                size: size,
                displayStyle: displayStyle,
            )
        case let .radical(radicand):
            try layoutRadical(radicand, size: size, displayStyle: displayStyle)
        case let .scripts(base, subscriptNode, superscriptNode):
            try layoutScripts(
                base: base,
                subscriptNode: subscriptNode,
                superscriptNode: superscriptNode,
                size: size,
                displayStyle: displayStyle,
            )
        case let .accent(symbol, _, isOverline, base):
            try layoutAccent(
                symbol: symbol,
                isOverline: isOverline,
                base: base,
                size: size,
                displayStyle: displayStyle,
            )
        case let .matrix(rows, open, close, leftAlign):
            try layoutMatrix(
                rows: rows,
                open: open,
                close: close,
                leftAlign: leftAlign,
                size: size,
            )
        case let .scaledDelimiter(symbol, scale):
            try layoutText(symbol, size: size * scale)
        }
    }

    private func layoutMatrix(
        rows: [[MathNode]],
        open: String,
        close: String,
        leftAlign: Bool,
        size: Double,
    ) throws -> MathBox {
        let cellBoxes = try rows.map { try $0.map { try layout($0, size: size, displayStyle: false) } }
        guard let columnCount = cellBoxes.map(\.count).max(), columnCount > 0 else {
            return MathBox(width: 0, height: 0, depth: 0, elements: [])
        }

        var columnWidths = [Double](repeating: 0, count: columnCount)
        for row in cellBoxes {
            for (column, box) in row.enumerated() {
                columnWidths[column] = max(columnWidths[column], box.width)
            }
        }
        let columnGap = size * 0.6
        let rowGap = size * 0.3
        let rowHeights = cellBoxes.map { $0.map(\.height).max() ?? metrics.textHeight(size: size) }
        let rowDepths = cellBoxes.map { $0.map(\.depth).max() ?? metrics.textDepth(size: size) }
        let stackHeight = zip(rowHeights, rowDepths).reduce(0) { $0 + $1.0 + $1.1 }
            + rowGap * Double(max(0, cellBoxes.count - 1))
        let axisY = metrics.axisHeight(size: size)
        let topY = axisY + stackHeight / 2
        let gridWidth = columnWidths.reduce(0, +) + columnGap * Double(max(0, columnCount - 1))
        let delimiterSize = min(max(stackHeight, size), size * 3)
        let delimiterY = axisY - delimiterSize * 0.3

        var elements: [MathLayoutElement] = []
        var xOrigin = 0.0
        if !open.isEmpty {
            let openBox = try layoutText(open, size: delimiterSize)
            elements += openBox.elements.map { $0.offsetBy(x: 0, y: delimiterY) }
            xOrigin = openBox.width + columnGap * 0.5
        }

        var cursorY = topY
        for (rowIndex, row) in cellBoxes.enumerated() {
            let rowBaseline = cursorY - rowHeights[rowIndex]
            var columnX = xOrigin
            for column in 0 ..< columnCount {
                if column < row.count {
                    let box = row[column]
                    let cellX = columnX + (leftAlign ? 0 : (columnWidths[column] - box.width) / 2)
                    elements += box.elements.map { $0.offsetBy(x: cellX, y: rowBaseline) }
                }
                columnX += columnWidths[column] + columnGap
            }
            cursorY = rowBaseline - rowDepths[rowIndex] - rowGap
        }

        var totalWidth = xOrigin + gridWidth
        if !close.isEmpty {
            let closeBox = try layoutText(close, size: delimiterSize)
            elements += closeBox.elements.map { $0.offsetBy(x: totalWidth + columnGap * 0.5, y: delimiterY) }
            totalWidth += columnGap * 0.5 + closeBox.width
        }

        return MathBox(
            width: totalWidth,
            height: topY,
            depth: max(0, stackHeight / 2 - axisY),
            elements: elements,
        )
    }

    private func layoutAccent(
        symbol: String,
        isOverline: Bool,
        base: MathNode,
        size: Double,
        displayStyle: Bool,
    ) throws -> MathBox {
        let baseBox = try layout(base, size: size, displayStyle: displayStyle)
        let gap = size * 0.12
        let ruleThickness = metrics.radicalRuleThickness(size: size)
        var elements = baseBox.elements

        if isOverline {
            let ruleY = baseBox.height + gap
            elements.append(.rule(
                x: 0,
                y: ruleY,
                width: baseBox.width,
                height: ruleThickness,
                color: color,
            ))
            return MathBox(
                width: baseBox.width,
                height: ruleY + ruleThickness,
                depth: baseBox.depth,
                elements: elements,
            )
        }

        let accentSize = size * 0.9
        let accent = try layoutText(symbol, size: accentSize)
        let accentX = max(0, (baseBox.width - accent.width) / 2)
        let accentY = baseBox.height + gap
        elements += accent.elements.map { $0.offsetBy(x: accentX, y: accentY) }
        return MathBox(
            width: max(baseBox.width, accentX + accent.width),
            height: accentY + accent.height,
            depth: baseBox.depth,
            elements: elements,
        )
    }

    private func layoutSequence(
        _ children: [MathNode],
        size: Double,
        displayStyle: Bool,
    ) throws -> MathBox {
        var cursor = 0.0
        var elements: [MathLayoutElement] = []
        var height = 0.0
        var depth = 0.0

        for child in children {
            let box = try layout(child, size: size, displayStyle: displayStyle)
            elements += box.elements.map { $0.offsetBy(x: cursor, y: 0) }
            cursor += box.width
            height = max(height, box.height)
            depth = max(depth, box.depth)
        }

        return MathBox(width: cursor, height: height, depth: depth, elements: elements)
    }

    private func layoutText(_ text: String, size: Double) throws -> MathBox {
        guard !text.isEmpty else {
            return MathBox(width: 0, height: 0, depth: 0, elements: [])
        }

        let run = MathRun(text: text, font: font, size: size, color: color)
        return try MathBox(
            width: measureText(run),
            height: metrics.textHeight(size: size),
            depth: metrics.textDepth(size: size),
            elements: [.text(run: run, x: 0, y: 0)],
        )
    }

    private func layoutFraction(
        numerator: MathNode,
        denominator: MathNode,
        size: Double,
        displayStyle: Bool,
    ) throws -> MathBox {
        let childSize = metrics.fractionChildSize(size: size)
        let numeratorBox = try layout(numerator, size: childSize, displayStyle: false)
        let denominatorBox = try layout(denominator, size: childSize, displayStyle: false)
        let padding = metrics.fractionPadding(size: size)
        let numeratorGap = metrics.fractionNumeratorGap(size: size, displayStyle: displayStyle)
        let denominatorGap = metrics.fractionDenominatorGap(size: size, displayStyle: displayStyle)
        let ruleThickness = metrics.fractionRuleThickness(size: size)
        let axisY = metrics.axisHeight(size: size)
        let ruleY = axisY - ruleThickness / 2
        let width = max(numeratorBox.width, denominatorBox.width) + padding * 2
        let numeratorBaseline = axisY + ruleThickness / 2 + numeratorGap + numeratorBox.depth
        let denominatorBaseline = axisY - ruleThickness / 2 - denominatorGap - denominatorBox.height
        let numeratorX = (width - numeratorBox.width) / 2
        let denominatorX = (width - denominatorBox.width) / 2

        var elements: [MathLayoutElement] = [
            .rule(x: 0, y: ruleY, width: width, height: ruleThickness, color: color),
        ]
        elements += numeratorBox.elements.map { $0.offsetBy(x: numeratorX, y: numeratorBaseline) }
        elements += denominatorBox.elements.map { $0.offsetBy(x: denominatorX, y: denominatorBaseline) }
        let ruleHeight = max(axisY + ruleThickness / 2, 0)
        let ruleDepth = max(-(axisY - ruleThickness / 2), 0)

        return MathBox(
            width: width,
            height: max(ruleHeight, numeratorBaseline + numeratorBox.height),
            depth: max(ruleDepth, abs(denominatorBaseline) + denominatorBox.depth),
            elements: elements,
        )
    }

    private func layoutRadical(
        _ radicand: MathNode,
        size: Double,
        displayStyle: Bool,
    ) throws -> MathBox {
        let radical = try layoutText("sqrt", size: metrics.radicalSignSize(size: size))
        let radicandBox = try layout(radicand, size: metrics.radicalRadicandSize(size: size), displayStyle: displayStyle)
        let gap = metrics.radicalHorizontalGap(size: size)
        let verticalGap = metrics.radicalVerticalGap(size: size, displayStyle: displayStyle)
        let ruleThickness = metrics.radicalRuleThickness(size: size)
        let extraAscender = metrics.radicalExtraAscender(size: size)
        let radicandX = radical.width + gap
        let overbarY = radicandBox.height + verticalGap

        var elements = radical.elements
        elements += radicandBox.elements.map { $0.offsetBy(x: radicandX, y: 0) }
        elements.append(.rule(
            x: radicandX,
            y: overbarY,
            width: radicandBox.width,
            height: ruleThickness,
            color: color,
        ))

        return MathBox(
            width: radical.width + gap + radicandBox.width,
            height: max(radical.height, overbarY + ruleThickness + extraAscender),
            depth: max(radical.depth, radicandBox.depth),
            elements: elements,
        )
    }

    private func layoutScripts(
        base: MathNode,
        subscriptNode: MathNode?,
        superscriptNode: MathNode?,
        size: Double,
        displayStyle: Bool,
    ) throws -> MathBox {
        if displayStyle, base.isBigOperator {
            return try layoutLimits(
                base: base,
                lower: subscriptNode,
                upper: superscriptNode,
                size: size,
            )
        }

        let baseBox = try layout(base, size: size, displayStyle: displayStyle)
        let scriptSize = metrics.scriptSize(size: size)
        let subscriptBox = try subscriptNode.map { try layout($0, size: scriptSize, displayStyle: false) }
        let superscriptBox = try superscriptNode.map { try layout($0, size: scriptSize, displayStyle: false) }
        let scriptGap = metrics.spaceAfterScript(size: size)
        let scriptX = baseBox.width + scriptGap
        let superscriptY = metrics.superscriptShiftUp(size: size, baseBox: baseBox)
        let subscriptY = -metrics.subscriptShiftDown(size: size, baseBox: baseBox, scriptSize: scriptSize)

        var elements = baseBox.elements
        var scriptWidth = 0.0
        var height = baseBox.height
        var depth = baseBox.depth

        if let superscriptBox {
            elements += superscriptBox.elements.map { $0.offsetBy(x: scriptX, y: superscriptY) }
            scriptWidth = max(scriptWidth, superscriptBox.width)
            height = max(height, superscriptY + superscriptBox.height)
        }

        if let subscriptBox {
            elements += subscriptBox.elements.map { $0.offsetBy(x: scriptX, y: subscriptY) }
            scriptWidth = max(scriptWidth, subscriptBox.width)
            depth = max(depth, abs(subscriptY) + subscriptBox.depth)
        }

        return MathBox(
            width: baseBox.width + scriptGap + scriptWidth,
            height: height,
            depth: depth,
            elements: elements,
        )
    }

    private func layoutLimits(
        base: MathNode,
        lower: MathNode?,
        upper: MathNode?,
        size: Double,
    ) throws -> MathBox {
        let baseBox = try layout(base, size: metrics.displayOperatorSize(size: size), displayStyle: false)
        let scriptSize = metrics.scriptSize(size: size)
        let lowerBox = try lower.map { try layout($0, size: scriptSize, displayStyle: false) }
        let upperBox = try upper.map { try layout($0, size: scriptSize, displayStyle: false) }
        let upperGap = metrics.upperLimitGap(size: size)
        let lowerGap = metrics.lowerLimitGap(size: size)
        let width = max(baseBox.width, lowerBox?.width ?? 0, upperBox?.width ?? 0)
        let baseX = (width - baseBox.width) / 2

        var elements = baseBox.elements.map { $0.offsetBy(x: baseX, y: 0) }
        var height = baseBox.height
        var depth = baseBox.depth

        if let upperBox {
            let upperY = baseBox.height + upperGap + upperBox.depth
            elements += upperBox.elements.map { $0.offsetBy(x: (width - upperBox.width) / 2, y: upperY) }
            height = upperY + upperBox.height
        }

        if let lowerBox {
            let lowerY = -baseBox.depth - lowerGap - lowerBox.height
            elements += lowerBox.elements.map { $0.offsetBy(x: (width - lowerBox.width) / 2, y: lowerY) }
            depth = abs(lowerY) + lowerBox.depth
        }

        return MathBox(width: width, height: height, depth: depth, elements: elements)
    }
}

private extension MathNode {
    var isBigOperator: Bool {
        if case let .symbol(_, _, isBigOperator) = self {
            return isBigOperator
        }
        return false
    }
}
