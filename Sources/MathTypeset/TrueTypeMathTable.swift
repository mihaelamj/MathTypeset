import Foundation

/// Parsed OpenType `MATH` table. `constants` drives `MathLayoutMetrics`; the
/// glyph info and variants are exposed for consumers that build stretchy
/// delimiters or glyph assemblies. All members are public so a consumer that
/// parses fonts itself can construct and inspect the table.
public struct TrueTypeMathTable: Equatable {
    public struct MathValueRecord: Equatable, Sendable {
        public var value: Int16
        public var deviceOffset: UInt16

        public init(value: Int16, deviceOffset: UInt16) {
            self.value = value
            self.deviceOffset = deviceOffset
        }
    }

    public struct Constants: Equatable, Sendable {
        public enum ValueName: String, CaseIterable, Sendable {
            case mathLeading
            case axisHeight
            case accentBaseHeight
            case flattenedAccentBaseHeight
            case subscriptShiftDown
            case subscriptTopMax
            case subscriptBaselineDropMin
            case superscriptShiftUp
            case superscriptShiftUpCramped
            case superscriptBottomMin
            case superscriptBaselineDropMax
            case subSuperscriptGapMin
            case superscriptBottomMaxWithSubscript
            case spaceAfterScript
            case upperLimitGapMin
            case upperLimitBaselineRiseMin
            case lowerLimitGapMin
            case lowerLimitBaselineDropMin
            case stackTopShiftUp
            case stackTopDisplayStyleShiftUp
            case stackBottomShiftDown
            case stackBottomDisplayStyleShiftDown
            case stackGapMin
            case stackDisplayStyleGapMin
            case stretchStackTopShiftUp
            case stretchStackBottomShiftDown
            case stretchStackGapAboveMin
            case stretchStackGapBelowMin
            case fractionNumeratorShiftUp
            case fractionNumeratorDisplayStyleShiftUp
            case fractionDenominatorShiftDown
            case fractionDenominatorDisplayStyleShiftDown
            case fractionNumeratorGapMin
            case fractionNumDisplayStyleGapMin
            case fractionRuleThickness
            case fractionDenominatorGapMin
            case fractionDenomDisplayStyleGapMin
            case skewedFractionHorizontalGap
            case skewedFractionVerticalGap
            case overbarVerticalGap
            case overbarRuleThickness
            case overbarExtraAscender
            case underbarVerticalGap
            case underbarRuleThickness
            case underbarExtraDescender
            case radicalVerticalGap
            case radicalDisplayStyleVerticalGap
            case radicalRuleThickness
            case radicalExtraAscender
            case radicalKernBeforeDegree
            case radicalKernAfterDegree
        }

        public var scriptPercentScaleDown: Int16
        public var scriptScriptPercentScaleDown: Int16
        public var delimitedSubFormulaMinHeight: UInt16
        public var displayOperatorMinHeight: UInt16
        public var values: [ValueName: MathValueRecord]
        public var radicalDegreeBottomRaisePercent: Int16

        public init(
            scriptPercentScaleDown: Int16,
            scriptScriptPercentScaleDown: Int16,
            delimitedSubFormulaMinHeight: UInt16,
            displayOperatorMinHeight: UInt16,
            values: [ValueName: MathValueRecord],
            radicalDegreeBottomRaisePercent: Int16,
        ) {
            self.scriptPercentScaleDown = scriptPercentScaleDown
            self.scriptScriptPercentScaleDown = scriptScriptPercentScaleDown
            self.delimitedSubFormulaMinHeight = delimitedSubFormulaMinHeight
            self.displayOperatorMinHeight = displayOperatorMinHeight
            self.values = values
            self.radicalDegreeBottomRaisePercent = radicalDegreeBottomRaisePercent
        }

        public func value(_ name: ValueName) -> MathValueRecord? {
            values[name]
        }
    }

    public struct GlyphValueRecord: Equatable {
        public var glyphID: UInt16
        public var value: MathValueRecord

        public init(glyphID: UInt16, value: MathValueRecord) {
            self.glyphID = glyphID
            self.value = value
        }
    }

    public struct GlyphInfo: Equatable {
        public var italicsCorrections: [GlyphValueRecord]
        public var topAccentAttachments: [GlyphValueRecord]
        public var extendedShapeGlyphIDs: [UInt16]
        public var mathKerns: [MathKernRecord]

        public init(
            italicsCorrections: [GlyphValueRecord],
            topAccentAttachments: [GlyphValueRecord],
            extendedShapeGlyphIDs: [UInt16],
            mathKerns: [MathKernRecord],
        ) {
            self.italicsCorrections = italicsCorrections
            self.topAccentAttachments = topAccentAttachments
            self.extendedShapeGlyphIDs = extendedShapeGlyphIDs
            self.mathKerns = mathKerns
        }
    }

    public struct MathKernRecord: Equatable {
        public var glyphID: UInt16
        public var topRight: MathKern?
        public var topLeft: MathKern?
        public var bottomRight: MathKern?
        public var bottomLeft: MathKern?

        public init(
            glyphID: UInt16,
            topRight: MathKern?,
            topLeft: MathKern?,
            bottomRight: MathKern?,
            bottomLeft: MathKern?,
        ) {
            self.glyphID = glyphID
            self.topRight = topRight
            self.topLeft = topLeft
            self.bottomRight = bottomRight
            self.bottomLeft = bottomLeft
        }
    }

    public struct MathKern: Equatable {
        public var correctionHeights: [MathValueRecord]
        public var kernValues: [MathValueRecord]

        public init(correctionHeights: [MathValueRecord], kernValues: [MathValueRecord]) {
            self.correctionHeights = correctionHeights
            self.kernValues = kernValues
        }
    }

    public struct Variants: Equatable {
        public var minConnectorOverlap: UInt16
        public var verticalConstructions: [GlyphConstruction]
        public var horizontalConstructions: [GlyphConstruction]

        public init(
            minConnectorOverlap: UInt16,
            verticalConstructions: [GlyphConstruction],
            horizontalConstructions: [GlyphConstruction],
        ) {
            self.minConnectorOverlap = minConnectorOverlap
            self.verticalConstructions = verticalConstructions
            self.horizontalConstructions = horizontalConstructions
        }
    }

    public struct GlyphConstruction: Equatable {
        public var glyphID: UInt16
        public var assembly: GlyphAssembly?
        public var variants: [GlyphVariant]

        public init(glyphID: UInt16, assembly: GlyphAssembly?, variants: [GlyphVariant]) {
            self.glyphID = glyphID
            self.assembly = assembly
            self.variants = variants
        }
    }

    public struct GlyphVariant: Equatable {
        public var glyphID: UInt16
        public var advanceMeasurement: UInt16

        public init(glyphID: UInt16, advanceMeasurement: UInt16) {
            self.glyphID = glyphID
            self.advanceMeasurement = advanceMeasurement
        }
    }

    public struct GlyphAssembly: Equatable {
        public var italicsCorrection: MathValueRecord
        public var parts: [GlyphPart]

        public init(italicsCorrection: MathValueRecord, parts: [GlyphPart]) {
            self.italicsCorrection = italicsCorrection
            self.parts = parts
        }
    }

    public struct GlyphPart: Equatable {
        public var glyphID: UInt16
        public var startConnectorLength: UInt16
        public var endConnectorLength: UInt16
        public var fullAdvance: UInt16
        public var partFlags: UInt16

        public init(
            glyphID: UInt16,
            startConnectorLength: UInt16,
            endConnectorLength: UInt16,
            fullAdvance: UInt16,
            partFlags: UInt16,
        ) {
            self.glyphID = glyphID
            self.startConnectorLength = startConnectorLength
            self.endConnectorLength = endConnectorLength
            self.fullAdvance = fullAdvance
            self.partFlags = partFlags
        }

        public var isExtender: Bool {
            partFlags & 0x0001 != 0
        }
    }

    public var majorVersion: UInt16
    public var minorVersion: UInt16
    public var constants: Constants
    public var glyphInfo: GlyphInfo
    public var variants: Variants

    public init(
        majorVersion: UInt16,
        minorVersion: UInt16,
        constants: Constants,
        glyphInfo: GlyphInfo,
        variants: Variants,
    ) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.constants = constants
        self.glyphInfo = glyphInfo
        self.variants = variants
    }
}
