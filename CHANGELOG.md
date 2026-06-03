# Changelog

All notable changes to MathTypeset are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
