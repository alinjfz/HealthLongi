import Foundation

/// Phase 2: On-device lab report OCR using Vision framework.
/// Parses recognized text against `LabBiomarker.ocrAliases` — never sends data off-device.
enum LabReportOCRService {
    struct ParsedValue: Identifiable {
        let id = UUID()
        let marker: LabBiomarker
        let value: Double
        let confidence: Float
    }

    /// Stub for Phase 2 — returns empty until Vision integration is wired.
    static func parseReportText(_ text: String) -> [ParsedValue] {
        var results: [ParsedValue] = []
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            for marker in LabBiomarker.allCases {
                for alias in marker.ocrAliases {
                    if line.localizedCaseInsensitiveContains(alias),
                       let value = extractNumber(from: line) {
                        results.append(ParsedValue(marker: marker, value: value, confidence: 0.7))
                        break
                    }
                }
            }
        }
        return results
    }

    private static func extractNumber(from line: String) -> Double? {
        let pattern = #"(\d+[.,]?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 1), in: line) else { return nil }
        let token = line[range].replacingOccurrences(of: ",", with: ".")
        return Double(token)
    }
}
