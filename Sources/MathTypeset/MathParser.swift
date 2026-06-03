import Foundation

public struct MathParser {
    public struct ParsedFormula: Equatable, Sendable {
        public var root: MathNode
        public var linearizedText: String

        public init(root: MathNode, linearizedText: String) {
            self.root = root
            self.linearizedText = linearizedText
        }
    }

    public enum ParseError: Error, Equatable, Sendable {
        case emptyFormula
        case duplicateScript(Character)
        case missingScriptBody(Character)
        case missingRequiredGroup(String)
        case missingRightDelimiter
        case missingDelimiter(String)
        case unmatchedGroup
        case unexpectedGroupClose
        case unsupportedControlWord(String)
    }

    public init() {}

    public func parse(_ source: String) throws -> ParsedFormula {
        var scanner = Scanner(source: source)
        let root = try scanner.parse()
        return ParsedFormula(root: root, linearizedText: MathLinearizer().linearize(root))
    }

    private struct Scanner {
        var source: String
        var index: String.Index

        init(source: String) {
            self.source = source
            index = source.startIndex
        }

        mutating func parse() throws -> MathNode {
            let root = try parseSequence(until: nil)
            guard !root.isEmptyMathSequence else {
                throw ParseError.emptyFormula
            }
            return root
        }

        private mutating func parseSequence(
            until terminator: Character?,
            stopAtRightDelimiter: Bool = false,
        ) throws -> MathNode {
            var nodes: [MathNode] = []

            while index < source.endIndex {
                let character = source[index]
                if stopAtRightDelimiter, controlWord(at: index)?.command == "right" {
                    return compactSequence(nodes)
                }
                if let terminator, character == terminator {
                    index = source.index(after: index)
                    return compactSequence(nodes)
                }
                if character == "}" {
                    throw ParseError.unexpectedGroupClose
                }

                try nodes.append(parseAtomWithScripts())
            }

            if terminator != nil {
                throw ParseError.unmatchedGroup
            }
            if stopAtRightDelimiter {
                throw ParseError.missingRightDelimiter
            }

            return compactSequence(nodes)
        }

        private mutating func parseAtomWithScripts() throws -> MathNode {
            var base = try parseAtom()
            var subscriptNode: MathNode?
            var superscriptNode: MathNode?

            while index < source.endIndex {
                let marker = source[index]
                guard marker == "^" || marker == "_" else {
                    break
                }

                index = source.index(after: index)
                let script = try parseScriptBody(marker)
                if marker == "^" {
                    guard superscriptNode == nil else {
                        throw ParseError.duplicateScript(marker)
                    }
                    superscriptNode = script
                } else {
                    guard subscriptNode == nil else {
                        throw ParseError.duplicateScript(marker)
                    }
                    subscriptNode = script
                }
            }

            if subscriptNode != nil || superscriptNode != nil {
                base = .scripts(base: base, subscript: subscriptNode, superscript: superscriptNode)
            }
            return base
        }

        private mutating func parseAtom() throws -> MathNode {
            guard index < source.endIndex else {
                throw ParseError.emptyFormula
            }

            let character = source[index]
            if character == "{" {
                index = source.index(after: index)
                return try parseSequence(until: "}")
            }
            if character == "\\" {
                return try parseControlWord()
            }
            if character == "^" || character == "_" {
                throw ParseError.missingScriptBody(character)
            }
            if character.isWhitespace {
                return parseWhitespace()
            }

            index = source.index(after: index)
            return .text(String(character))
        }

        private mutating func parseWhitespace() -> MathNode {
            while index < source.endIndex, source[index].isWhitespace {
                index = source.index(after: index)
            }
            return .text(" ")
        }

        private mutating func parseControlWord() throws -> MathNode {
            index = source.index(after: index)
            let commandStart = index
            while index < source.endIndex, source[index].isLetter {
                index = source.index(after: index)
            }

            let command = String(source[commandStart ..< index])
            if command.isEmpty {
                return try parseEscapedPunctuation()
            }

            switch command {
            case "frac":
                return try .fraction(
                    numerator: parseRequiredGroup(for: command),
                    denominator: parseRequiredGroup(for: command),
                )
            case "sqrt":
                return try .radical(radicand: parseRequiredGroup(for: command))
            case "left":
                return try parseDelimitedExpression()
            case "operatorname":
                let name = try MathLinearizer().linearize(parseRequiredGroup(for: command))
                return .symbol(display: name, linearized: name, isBigOperator: false)
            case "begin":
                return try parseMatrixEnvironment()
            case "big", "Big", "bigg", "Bigg":
                return try parseScaledDelimiter(scale: Self.delimiterScales[command] ?? 1)
            case "right", "end", "newcommand":
                throw ParseError.unsupportedControlWord(command)
            default:
                if let accent = Self.accents[command] {
                    return try .accent(
                        symbol: accent.symbol,
                        linearized: accent.linearized,
                        isOverline: accent.isOverline,
                        base: parseRequiredGroup(for: command),
                    )
                }
                guard let symbol = Self.symbols[command] else {
                    throw ParseError.unsupportedControlWord(command)
                }
                return .symbol(
                    display: symbol.display,
                    linearized: symbol.linearized,
                    isBigOperator: symbol.isBigOperator,
                )
            }
        }

        private mutating func parseDelimitedExpression() throws -> MathNode {
            skipWhitespace()
            let opening = try parseDelimiter(for: "left")
            let body = try parseSequence(until: nil, stopAtRightDelimiter: true)
            guard controlWord(at: index)?.command == "right" else {
                throw ParseError.missingRightDelimiter
            }

            try consumeControlWord("right")
            skipWhitespace()
            let closing = try parseDelimiter(for: "right")
            return compactSequence([opening, body, closing])
        }

        private mutating func parseScaledDelimiter(scale: Double) throws -> MathNode {
            skipWhitespace()
            let delimiter = try parseDelimiter(for: "big")
            if case let .text(symbol) = delimiter {
                return .scaledDelimiter(symbol: symbol, scale: scale)
            }
            return delimiter
        }

        private mutating func parseMatrixEnvironment() throws -> MathNode {
            let name = try parseEnvironmentName()
            guard let env = Self.matrixEnvironments[name] else {
                throw ParseError.unsupportedControlWord("begin{\(name)}")
            }

            var rows: [[MathNode]] = []
            var row: [MathNode] = []
            while true {
                try row.append(parseMatrixCell())
                guard index < source.endIndex else {
                    throw ParseError.unmatchedGroup
                }
                if source[index] == "&" {
                    index = source.index(after: index)
                    continue
                }
                if isRowSeparator() {
                    index = source.index(index, offsetBy: 2)
                    rows.append(row)
                    row = []
                    continue
                }
                if controlWord(at: index)?.command == "end" {
                    try consumeControlWord("end")
                    _ = try parseEnvironmentName()
                    rows.append(row)
                    break
                }
                throw ParseError.unmatchedGroup
            }

            if let last = rows.last, last.count == 1, last[0].isEmptyMathSequence {
                rows.removeLast()
            }
            return .matrix(rows: rows, open: env.open, close: env.close, leftAlign: env.leftAlign)
        }

        private mutating func parseEnvironmentName() throws -> String {
            skipWhitespace()
            guard index < source.endIndex, source[index] == "{" else {
                throw ParseError.missingRequiredGroup("begin")
            }
            index = source.index(after: index)
            let start = index
            while index < source.endIndex, source[index] != "}" {
                index = source.index(after: index)
            }
            guard index < source.endIndex else {
                throw ParseError.unmatchedGroup
            }
            let name = String(source[start ..< index])
            index = source.index(after: index)
            return name.trimmingCharacters(in: .whitespaces)
        }

        private mutating func parseMatrixCell() throws -> MathNode {
            var nodes: [MathNode] = []
            while index < source.endIndex {
                let character = source[index]
                if character == "&" || isRowSeparator() {
                    break
                }
                if character == "\\", controlWord(at: index)?.command == "end" {
                    break
                }
                if character == "}" {
                    throw ParseError.unexpectedGroupClose
                }
                try nodes.append(parseAtomWithScripts())
            }
            return compactSequence(nodes)
        }

        private func isRowSeparator() -> Bool {
            guard index < source.endIndex, source[index] == "\\" else {
                return false
            }
            let next = source.index(after: index)
            return next < source.endIndex && source[next] == "\\"
        }

        private mutating func skipWhitespace() {
            while index < source.endIndex, source[index].isWhitespace {
                index = source.index(after: index)
            }
        }

        private mutating func parseDelimiter(for command: String) throws -> MathNode {
            guard index < source.endIndex else {
                throw ParseError.missingDelimiter(command)
            }

            if source[index] == "\\" {
                let slash = index
                index = source.index(after: index)
                let commandStart = index
                while index < source.endIndex, source[index].isLetter {
                    index = source.index(after: index)
                }

                if commandStart == index {
                    return try parseEscapedDelimiter(for: command)
                }

                let delimiterCommand = String(source[commandStart ..< index])
                guard let display = Self.namedDelimiters[delimiterCommand] else {
                    index = slash
                    throw ParseError.missingDelimiter(command)
                }
                return display.map(MathNode.text) ?? .sequence([])
            }

            let character = source[index]
            index = source.index(after: index)
            guard let display = Self.characterDelimiters[character] else {
                throw ParseError.missingDelimiter(command)
            }
            return display.map(MathNode.text) ?? .sequence([])
        }

        private mutating func parseEscapedDelimiter(for command: String) throws -> MathNode {
            guard index < source.endIndex else {
                throw ParseError.missingDelimiter(command)
            }

            let character = source[index]
            index = source.index(after: index)
            guard let display = Self.characterDelimiters[character] else {
                throw ParseError.missingDelimiter(command)
            }
            return display.map(MathNode.text) ?? .sequence([])
        }

        private func controlWord(at start: String.Index) -> (command: String, end: String.Index)? {
            guard start < source.endIndex, source[start] == "\\" else {
                return nil
            }

            var cursor = source.index(after: start)
            let commandStart = cursor
            while cursor < source.endIndex, source[cursor].isLetter {
                cursor = source.index(after: cursor)
            }
            guard commandStart < cursor else {
                return nil
            }

            return (String(source[commandStart ..< cursor]), cursor)
        }

        private mutating func consumeControlWord(_ expected: String) throws {
            guard let word = controlWord(at: index),
                  word.command == expected
            else {
                throw ParseError.unsupportedControlWord(expected)
            }

            index = word.end
        }

        private mutating func parseEscapedPunctuation() throws -> MathNode {
            guard index < source.endIndex else {
                throw ParseError.unsupportedControlWord("")
            }

            let character = source[index]
            index = source.index(after: index)
            switch character {
            case "{", "}", "_", "^", "\\", "$":
                return .text(String(character))
            default:
                throw ParseError.unsupportedControlWord(String(character))
            }
        }

        private mutating func parseRequiredGroup(for command: String) throws -> MathNode {
            guard index < source.endIndex, source[index] == "{" else {
                throw ParseError.missingRequiredGroup(command)
            }

            index = source.index(after: index)
            return try parseSequence(until: "}")
        }

        private mutating func parseScriptBody(_ marker: Character) throws -> MathNode {
            guard index < source.endIndex else {
                throw ParseError.missingScriptBody(marker)
            }

            if source[index] == "{" {
                index = source.index(after: index)
                return try parseSequence(until: "}")
            }
            return try parseAtom()
        }

        private func compactSequence(_ nodes: [MathNode]) -> MathNode {
            let nonEmpty = nodes.filter { !$0.isEmptyMathSequence }
            if nonEmpty.count == 1, let first = nonEmpty.first {
                return first
            }
            return .sequence(nonEmpty)
        }

        private static let delimiterScales: [String: Double] = [
            "big": 1.2,
            "Big": 1.8,
            "bigg": 2.4,
            "Bigg": 3.0,
        ]

        private static let matrixEnvironments: [String: (open: String, close: String, leftAlign: Bool)] = [
            "matrix": ("", "", false),
            "pmatrix": ("(", ")", false),
            "bmatrix": ("[", "]", false),
            "Bmatrix": ("{", "}", false),
            "vmatrix": ("|", "|", false),
            "Vmatrix": ("||", "||", false),
            "cases": ("{", "", true),
        ]

        private static let accents: [String: (symbol: String, linearized: String, isOverline: Bool)] = [
            "hat": ("^", "hat", false),
            "widehat": ("^", "hat", false),
            "tilde": ("~", "tilde", false),
            "widetilde": ("~", "tilde", false),
            "vec": (">", "vec", false),
            "dot": (".", "dot", false),
            "ddot": ("..", "ddot", false),
            "check": ("v", "check", false),
            "acute": ("'", "acute", false),
            "grave": ("`", "grave", false),
            "bar": ("", "bar", true),
            "overline": ("", "overline", true),
        ]

        private static let symbols: [String: (display: String, linearized: String, isBigOperator: Bool)] = [
            "alpha": ("α", "alpha", false),
            "beta": ("β", "beta", false),
            "gamma": ("γ", "gamma", false),
            "delta": ("δ", "delta", false),
            "epsilon": ("ε", "epsilon", false),
            "theta": ("θ", "theta", false),
            "lambda": ("λ", "lambda", false),
            "mu": ("μ", "mu", false),
            "pi": ("π", "pi", false),
            "sigma": ("σ", "sigma", false),
            "phi": ("φ", "phi", false),
            "omega": ("ω", "omega", false),
            "Gamma": ("Γ", "Gamma", false),
            "Delta": ("Δ", "Delta", false),
            "Theta": ("Θ", "Theta", false),
            "Lambda": ("Λ", "Lambda", false),
            "Pi": ("Π", "Pi", false),
            "Sigma": ("Σ", "Sigma", false),
            "Phi": ("Φ", "Phi", false),
            "Omega": ("Ω", "Omega", false),
            "leq": ("≤", "<=", false),
            "geq": ("≥", ">=", false),
            "neq": ("≠", "!=", false),
            "times": ("×", "x", false),
            "cdot": ("⋅", "*", false),
            "pm": ("±", "+/-", false),
            "infty": ("∞", "infinity", false),
            "rightarrow": ("→", "->", false),
            "to": ("→", "->", false),
            "zeta": ("ζ", "zeta", false),
            "eta": ("η", "eta", false),
            "iota": ("ι", "iota", false),
            "kappa": ("κ", "kappa", false),
            "nu": ("ν", "nu", false),
            "xi": ("ξ", "xi", false),
            "rho": ("ρ", "rho", false),
            "tau": ("τ", "tau", false),
            "upsilon": ("υ", "upsilon", false),
            "chi": ("χ", "chi", false),
            "psi": ("ψ", "psi", false),
            "varepsilon": ("ε", "epsilon", false),
            "varphi": ("ϕ", "phi", false),
            "vartheta": ("ϑ", "theta", false),
            "Xi": ("Ξ", "Xi", false),
            "Psi": ("Ψ", "Psi", false),
            "Upsilon": ("Υ", "Upsilon", false),
            "approx": ("≈", "~=", false),
            "equiv": ("≡", "equiv", false),
            "sim": ("∼", "~", false),
            "propto": ("∝", "propto", false),
            "ll": ("≪", "<<", false),
            "gg": ("≫", ">>", false),
            "subset": ("⊂", "subset", false),
            "supset": ("⊃", "supset", false),
            "subseteq": ("⊆", "subseteq", false),
            "supseteq": ("⊇", "supseteq", false),
            "in": ("∈", "in", false),
            "notin": ("∉", "notin", false),
            "ni": ("∋", "ni", false),
            "mid": ("∣", "|", false),
            "parallel": ("∥", "||", false),
            "leftarrow": ("←", "<-", false),
            "gets": ("←", "<-", false),
            "leftrightarrow": ("↔", "<->", false),
            "Rightarrow": ("⇒", "=>", false),
            "Leftarrow": ("⇐", "<==", false),
            "Leftrightarrow": ("⇔", "<=>", false),
            "mapsto": ("↦", "|->", false),
            "div": ("÷", "/", false),
            "ast": ("∗", "*", false),
            "star": ("⋆", "*", false),
            "circ": ("∘", "circ", false),
            "bullet": ("∙", "*", false),
            "oplus": ("⊕", "(+)", false),
            "ominus": ("⊖", "(-)", false),
            "otimes": ("⊗", "(x)", false),
            "cup": ("∪", "cup", false),
            "cap": ("∩", "cap", false),
            "wedge": ("∧", "wedge", false),
            "vee": ("∨", "vee", false),
            "emptyset": ("∅", "empty", false),
            "forall": ("∀", "forall", false),
            "exists": ("∃", "exists", false),
            "nabla": ("∇", "nabla", false),
            "partial": ("∂", "partial", false),
            "angle": ("∠", "angle", false),
            "ldots": ("…", "...", false),
            "cdots": ("⋯", "...", false),
            "dots": ("…", "...", false),
            "prime": ("′", "'", false),
            "hbar": ("ℏ", "hbar", false),
            "ell": ("ℓ", "l", false),
            "aleph": ("ℵ", "aleph", false),
            "sin": ("sin", "sin", false),
            "cos": ("cos", "cos", false),
            "tan": ("tan", "tan", false),
            "cot": ("cot", "cot", false),
            "sec": ("sec", "sec", false),
            "csc": ("csc", "csc", false),
            "log": ("log", "log", false),
            "ln": ("ln", "ln", false),
            "exp": ("exp", "exp", false),
            "deg": ("deg", "deg", false),
            "gcd": ("gcd", "gcd", false),
            "sum": ("∑", "sum", true),
            "prod": ("∏", "prod", true),
            "int": ("∫", "int", true),
            "oint": ("∮", "oint", true),
            "coprod": ("∐", "coprod", true),
            "bigcup": ("⋃", "bigcup", true),
            "bigcap": ("⋂", "bigcap", true),
            "lim": ("lim", "lim", true),
            "max": ("max", "max", true),
            "min": ("min", "min", true),
            "sup": ("sup", "sup", true),
            "inf": ("inf", "inf", true),
        ]

        private static let characterDelimiters: [Character: String?] = [
            "(": "(",
            ")": ")",
            "[": "[",
            "]": "]",
            "{": "{",
            "}": "}",
            "|": "|",
            "/": "/",
            "<": "<",
            ">": ">",
            ".": nil,
        ]

        private static let namedDelimiters: [String: String?] = [
            "langle": "<",
            "rangle": ">",
            "vert": "|",
            "lvert": "|",
            "rvert": "|",
            "backslash": "\\",
        ]
    }
}

private extension MathNode {
    var isEmptyMathSequence: Bool {
        if case let .sequence(children) = self {
            children.isEmpty
        } else {
            false
        }
    }
}
