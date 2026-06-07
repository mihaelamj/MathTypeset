# Changelog

All notable changes to MathTypeset are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- License changed from MIT to AGPL-3.0. MathTypeset is now dual licensed:
  AGPL-3.0 for open-source use, with a commercial license available for
  closed-source or otherwise AGPL-incompatible use (see `COMMERCIAL.md`).
  Versions published before this change remain available under their original
  MIT terms.

## [0.6.0]

### Added

- TeX horizontal spacing commands. New `MathNode.space(em:)` node, with the
  parser mapping `\quad` (1 em), `\qquad` (2 em), `\,` (thin), `\:` (medium),
  `\;` (thick), `\!` (negative thin), and `\ ` (control space) to em multiples.
  Layout draws nothing and only advances (or retreats) the cursor; the
  linearizer emits a single space. Previously these commands threw
  `unsupportedControlWord`, forcing the whole formula to a visible-source
  fallback in consumers. Additive.

## [0.5.0]

### Added

- `MathLayout.SymbolStyle.unicodeWhereCovered` plus a `symbolCoverage` closure on
  `MathLayout`. Each math symbol draws its Unicode glyph when the consumer's font
  covers it and the ASCII transliteration otherwise, decided per symbol by the
  closure. The engine stays font-program-free: the consumer owns the coverage
  lookup, exactly as it owns `measureText`. A font with full math coverage then
  behaves like `.unicode`, a base-14 font like `.asciiFallback`, and a partial
  font gets real glyphs where it can and a readable fallback where it cannot.
  Additive: `.unicode` and `.asciiFallback` are unchanged.

## [0.4.0]

### Changed

- The radical sign (`\\sqrt`) is now drawn as two **scaling vector strokes**
  instead of a fixed glyph, so it grows with the radicand height and its
  up-stroke meets the vinculum. Fixes the detached small-sign look on tall
  radicands.

### Added

- `MathLayoutElement.line(x1:y1:x2:y2:thickness:color:)`: a stroked segment for
  shapes a rule cannot express (the diagonal radical strokes), in the same
  baseline-relative +y-up space as the other elements.

### Breaking

- `MathLayoutElement` has a new `.line` case. Consumers that `switch` over it
  exhaustively must add a branch that strokes a line between the two points.

## [0.3.0]

### Changed

- Symbol commands now carry their **Unicode glyph** as the drawn `display`
  (`\\sum` -> ∑, `\\sqrt` -> √, `\\pm` -> ±, `\\leq` -> ≤, `\\infty` -> ∞, Greek letters, and
  the common operators, relations, and arrows) instead of an ASCII command word.
  The ASCII transliteration is retained as `linearized` (accessibility /
  extraction text) and is selectable at draw time.

### Added

- `MathLayout.SymbolStyle` (`.unicode` default, `.asciiFallback`) chooses whether
  runs draw the Unicode glyph or the ASCII transliteration, so a consumer whose
  font cannot draw math glyphs (e.g. a PDF base-14 profile) can opt into the
  fallback. The layout algorithm is unchanged; only the run text differs.

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
