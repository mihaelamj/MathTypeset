# MathTypeset

A small, dependency-free Swift package that typesets a TeX-math subset into a
neutral, positioned layout. It parses `\frac`, `\sqrt`, scripts, accents,
matrices, big operators, scaling and fixed delimiters, and an extended symbol
set, then lays them out with a box-and-glue engine driven by an OpenType `MATH`
table. The result is a backend-neutral `MathBox` that any consumer can emit to
PDF, SVG, or MathML.

The engine is extracted from the
[MarkdownPDF](https://github.com/mihaelamj/MarkdownPDF) renderer so it can be
shared with other projects without duplicating the layout and metrics work.

- Pure Swift, only `Foundation`. No PDF, AppKit, CoreGraphics, UIKit, or C
  libraries.
- Builds and tests on macOS and Linux.
- The package never renders pixels and never reads glyph outlines or `hmtx`
  advances. Font measurement and emission are the consumer's job.

## Install

```swift
.package(url: "https://github.com/mihaelamj/MathTypeset.git", from: "0.1.0"),
```

```swift
.target(name: "YourTarget", dependencies: ["MathTypeset"]),
```

## Usage

```swift
import MathTypeset

// 1. Parse a formula.
let parsed = try MathParser().parse(#"\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#)

// 2. Build metrics from the font's OpenType MATH table.
let table = try TrueTypeMathTableParser(bytes: mathTableBytes, numGlyphs: numGlyphs).parse()
let metrics = MathLayoutMetrics.openType(constants: table.constants, unitsPerEm: unitsPerEm)

// 3. Lay it out. `measureText` is your font measurement (see the contract).
let layout = MathLayout(
    font: .regular,
    color: .black,
    measureText: { run in myAdvanceWidth(of: run.text, at: run.size) },
    metrics: metrics,
)
let box = try layout.layout(parsed.root, size: 11, displayStyle: true)

// 4. Emit. Walk box.elements and draw each in your backend.
for element in box.elements {
    switch element {
    case let .text(run, x, y):
        draw(run.text, at: (x, y), size: run.size, color: run.color)
    case let .rule(x, y, width, height, color):
        fillRect(x: x, y: y, width: width, height: height, color: color)
    }
}
```

## The measurement contract

This is load-bearing. The layout never measures glyphs itself; it calls your
`measureText` closure and trusts the result. For the layout and the MATH-table
metrics to agree:

- `measureText(run)` returns the **advance width of `run.text`, set in `run.font`
  at `run.size`, in typographic points** (the same space `run.size` is in).
- `MathLayoutMetrics.openType(constants:unitsPerEm:)` must be given the
  `unitsPerEm` of the **same font** you measure against, so the MATH constants
  (font units) normalize to the same point space your advances use.
- The resulting `MathBox` (`width`, `height`, `depth`) and every element
  coordinate are in **points at the formula's base size**. Emit at those
  coordinates directly; do not rescale.

If you measure with one font but pass another font's `unitsPerEm`, or measure in
a different unit than `run.size`, advances and metrics will disagree and the
output will drift. Measure and feed metrics from one font artifact.

`baselineOffset` on a `MathRun` shifts that run vertically from the run's
baseline (used for scripts). `MathBox.depth` is the extent below the baseline,
useful for baseline-aligning inline math.

## Public surface

- `MathParser().parse(_:) -> MathParser.ParsedFormula` (`.root: MathNode`)
- `MathNode` (the AST)
- `MathLayout(font:color:measureText:metrics:).layout(_:size:displayStyle:) -> MathBox`
- `MathBox`, `MathLayoutElement` (`.text(run:x:y:)` / `.rule(...)`)
- `MathRun`, `MathFontStyle`, `MathColor`
- `MathLayoutMetrics.openType(constants:unitsPerEm:)` and `.default`
- `TrueTypeMathTableParser(bytes:numGlyphs:).parse() -> TrueTypeMathTable`
  (`.constants`)

## License

MathTypeset is dual licensed as [AGPL-3.0](LICENSE) / commercial.

The AGPL is a free, open-source license, but that does not mean the software is
free of obligations. It is a copyleft license: any derivative work, including
software or a network service that incorporates MathTypeset, must also be
released under the AGPL-3.0 with its complete corresponding source. If you are
building something that cannot comply with the AGPL terms, a
[commercial license](COMMERCIAL.md) is available that exempts you from them.

See [COMMERCIAL.md](COMMERCIAL.md) for commercial licensing.
