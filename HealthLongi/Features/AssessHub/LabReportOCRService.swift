import Foundation

/// On-device lab report parsing — never sends data off-device.
enum LabReportOCRService {
    struct ParsedValue: Identifiable {
        let id = UUID()
        let marker: LabBiomarker
        let value: Double
        let confidence: Float
    }

    static func parseReportText(_ text: String) -> [ParsedValue] {
        var byMarker: [LabBiomarker: ParsedValue] = [:]

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if shouldSkipLine(trimmed) { continue }

            if let tableMatch = parseMarkdownTableRow(trimmed) {
                applyMatch(name: tableMatch.name, value: tableMatch.value, into: &byMarker, confidence: 0.9)
                continue
            }

            for marker in LabBiomarker.allCases {
                guard byMarker[marker] == nil else { continue }
                for alias in marker.ocrAliases {
                    if trimmed.localizedCaseInsensitiveContains(alias),
                       let value = extractResultNumber(from: trimmed) {
                        byMarker[marker] = ParsedValue(marker: marker, value: value, confidence: 0.7)
                        break
                    }
                }
            }
        }

        return Array(byMarker.values).sorted { $0.marker.label < $1.marker.label }
    }

    static func parseReportDate(from text: String) -> Date? {
        let patterns = [
            #"Report Date:\s*(\d{2}-[A-Za-z]{3}-\d{4})"#,
            #"Report Date:\s*(\d{4}-\d{2}-\d{2})"#
        ]
        let formatters = ["dd-MMM-yyyy", "yyyy-MM-dd"]
        for (pattern, format) in zip(patterns, formatters) {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else { continue }
            let token = String(text[range])
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_GB")
            formatter.dateFormat = format
            if let date = formatter.date(from: token) { return date }
        }
        return nil
    }

    private static func shouldSkipLine(_ line: String) -> Bool {
        let lowered = line.lowercased()
        if lowered.contains("nhs number") || lowered.contains("hospital number") { return true }
        if lowered.hasPrefix("| field |") || lowered.hasPrefix("|---") { return true }
        if lowered.hasPrefix("## patient") { return true }
        return false
    }

    private struct TableRow {
        let name: String
        let value: Double
    }

    private static func parseMarkdownTableRow(_ line: String) -> TableRow? {
        guard line.contains("|") else { return nil }
        let cells = line
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard cells.count >= 2 else { return nil }

        let name = cells[0]
        if name.caseInsensitiveCompare("Investigation") == .orderedSame { return nil }
        if name.caseInsensitiveCompare("Field") == .orderedSame { return nil }

        guard let value = parseNumericToken(cells[1]) else { return nil }
        return TableRow(name: name, value: value)
    }

    private static func applyMatch(
        name: String,
        value: Double,
        into byMarker: inout [LabBiomarker: ParsedValue],
        confidence: Float
    ) {
        guard let marker = marker(forName: name) else { return }
        byMarker[marker] = ParsedValue(marker: marker, value: value, confidence: confidence)
    }

    private static func marker(forName name: String) -> LabBiomarker? {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespaces)

        for marker in LabBiomarker.allCases {
            for alias in marker.ocrAliases where alias.lowercased() == normalized {
                return marker
            }
        }

        var best: (marker: LabBiomarker, score: Int)?
        for marker in LabBiomarker.allCases {
            for alias in marker.ocrAliases {
                let aliasNorm = alias.lowercased()
                guard normalized.contains(aliasNorm) || aliasNorm.contains(normalized) else { continue }
                let score = aliasNorm.count
                if best == nil || score > best!.score {
                    best = (marker, score)
                }
            }
        }
        return best?.marker
    }

    private static func extractResultNumber(from line: String) -> Double? {
        if line.contains("|") {
            let cells = line.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
            if cells.count >= 2, let value = parseNumericToken(cells[1]) { return value }
        }
        return firstNumber(in: line)
    }

    private static func parseNumericToken(_ token: String) -> Double? {
        let cleaned = token
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    private static func firstNumber(in line: String) -> Double? {
        let pattern = #"(\d+[.,]?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, range: range)
        for match in matches {
            guard let numberRange = Range(match.range(at: 1), in: line) else { continue }
            let token = line[numberRange].replacingOccurrences(of: ",", with: ".")
            if let value = Double(token) { return value }
        }
        return nil
    }
}
