import Foundation

struct AISafetyFilter {
    private static let blockedPatterns: [NSRegularExpression] = {
        let patterns = [
            #"(?i)\byou have\b"#,
            #"(?i)\byou're diagnosed\b"#,
            #"(?i)\bdiagnosed with\b"#,
            #"(?i)\bdiagnosis is\b"#,
            #"(?i)\btake\s+\w+\b"#,
            #"(?i)\bprescribe\b"#,
            #"(?i)\bmetformin\b"#,
            #"(?i)\bstatins?\b"#,
            #"(?i)\bsertraline\b"#,
            #"(?i)\bfluoxetine\b"#,
            #"(?i)\bdiabetes\b"#,
            #"(?i)\bdepression\b"#,
            #"(?i)\bhypertension\b"#,
            #"(?i)\bcancer\b"#
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    static func isBlocked(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return blockedPatterns.contains { $0.firstMatch(in: text, range: range) != nil }
    }

    static func sanitize(_ text: String, fallback: String) -> String {
        isBlocked(text) ? fallback : text
    }
}
