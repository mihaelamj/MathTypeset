# Changelog

All notable changes to MathTypeset are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3]

### Added

- Add `TrueTypeByteReader.bytes(at:count:)` for bounds-checked N-byte / sub-slice
  reads (throws on overflow), for consumers walking variable-length structures
  such as CFF `INDEX` data.

## [0.2.2]

### Added

- Make `TrueTypeByteReader` public (bounds-checked big-endian accessors,
  plus `uint8(at:)`) so consumers parsing their own font tables can reuse it.

## [0.2.1]

### Added

- Make `MathLinearizer` public so consumers can linearize an arbitrary `MathNode`
  to readable text (for ActualText / accessibility), not only via the parser.

## [0.2.0]

### Added

- Make the full `TrueTypeMathTable` public and constructible (glyph info,
  variants, kerns, assemblies, and their records), not just `.constants`, so
  consumers that parse fonts themselves can inspect and build the table. Purely
  additive; no breaking changes.
- Exclude `.build` from SwiftLint at the repo root.

## [0.1.1]

### Fixed

- Move `Package.swift` to the repository root (from `Packages/`) so the package
  can be consumed as a SwiftPM git dependency. SwiftPM resolves the manifest
  only at the repo root, so `0.1.0` could not be depended on.

## [0.1.0]

### Added

- TeX-math subset parser (`MathParser`) covering fractions, radicals, scripts,
  accents, matrices and cases, big operators with limits, fixed and scaling
  delimiters, `operatorname`, and an extended symbol set, producing a `MathNode`
  AST and a linearized text form.
- Box-and-glue layout (`MathLayout`) producing a backend-neutral `MathBox` of
  positioned `MathRun` and rule elements, with point-space geometry.
- OpenType `MATH` table reader (`TrueTypeMathTableParser` -> `TrueTypeMathTable`)
  and metrics derived from it (`MathLayoutMetrics.openType`), with sensible
  defaults when no table is present.
- Neutral value types `MathRun`, `MathFontStyle` (extensible variants plus an
  optional opaque font id), and `MathColor`.
- Font measurement is injected through a `measureText` closure, so the package
  has no font, PDF, or platform dependency.
- macOS and Linux CI; parser and layout test suites.
