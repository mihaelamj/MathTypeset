# Contributing to MathTypeset

Thanks for your interest. MathTypeset is a small, dependency-free Swift package
that turns a TeX-math subset into a neutral, positioned layout box that any
backend (PDF, SVG, MathML) can emit.

## Principles

- **Pure Swift, zero dependencies.** Only the Swift standard library and
  `Foundation`. No PDF, AppKit, CoreGraphics, UIKit, or C libraries.
- **Backend-neutral.** The package produces a `MathBox` of neutral `MathRun`
  and rule elements. It never emits PDF, SVG, or MathML. Emission and font
  measurement belong to the consumer.
- **Cross-platform.** Builds and tests on macOS and Linux. Every change must
  keep both green.

## Build and test

```sh
cd Packages
swift build
swift test
```

## Style

```sh
swiftformat . --config .swiftformat
swiftlint --config .swiftlint.yml
```

Format and lint must be clean before a change lands.

## Pull requests

- Keep the public surface minimal and documented.
- Add or update tests for parser and layout changes; both `MathParser` and
  `MathLayout` suites must stay green.
- Use Conventional Commit messages (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Note any change to the `measureText` contract or the `MathBox` coordinate
  space in the README; downstream emitters depend on it.

## Scope

In scope: the TeX-math subset parser, the box-and-glue layout, the OpenType MATH
table reader, and the metrics derived from it. Out of scope: anything that reads
glyph outlines or `hmtx` advances, renders pixels, or targets a specific output
format. Those live in the consumer.
