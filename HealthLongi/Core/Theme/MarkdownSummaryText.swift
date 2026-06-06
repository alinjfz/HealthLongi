import SwiftUI

enum MarkdownBlock: Identifiable {
    case heading(String)
    case paragraph(String)
    case listItem(String)

    var id: String {
        switch self {
        case .heading(let text), .paragraph(let text), .listItem(let text):
            text
        }
    }
}

enum MarkdownSummaryFormatter {
    /// Removes redundant top-level headings the UI already shows as a title.
    static func forDisplay(_ markdown: String) -> String {
        var text = markdown.trimmingCharacters(in: .whitespacesAndNewlines)

        while let firstLine = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first {
            let line = String(firstLine).trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("#") else { break }

            let headingText = line.replacingOccurrences(
                of: #"^#+\s*"#,
                with: "",
                options: .regularExpression
            ).trimmingCharacters(in: .whitespaces)

            let normalized = headingText.lowercased()
            let isRedundantTitle = normalized.contains("health summary")
                || normalized == "summary"
                || normalized == "your summary"

            guard isRedundantTitle else { break }

            if let newlineIndex = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: newlineIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return ""
            }
        }

        return text
    }

    static func blocks(from markdown: String) -> [MarkdownBlock] {
        let text = forDisplay(markdown)
        guard !text.isEmpty else { return [] }

        var blocks: [MarkdownBlock] = []

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("#") {
                let heading = trimmed.replacingOccurrences(
                    of: #"^#+\s*"#,
                    with: "",
                    options: .regularExpression
                ).trimmingCharacters(in: .whitespaces)
                if !heading.isEmpty {
                    blocks.append(.heading(heading))
                }
            } else if trimmed.hasPrefix("- ") {
                blocks.append(.listItem(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("* ") {
                blocks.append(.listItem(String(trimmed.dropFirst(2))))
            } else if let listText = numberedListItem(from: trimmed) {
                blocks.append(.listItem(listText))
            } else {
                blocks.append(.paragraph(trimmed))
            }
        }

        return blocks
    }

    private static func numberedListItem(from line: String) -> String? {
        guard let dotIndex = line.firstIndex(of: "."),
              line[..<dotIndex].allSatisfy(\.isNumber) else {
            return nil
        }

        let afterDot = line.index(after: dotIndex)
        guard afterDot < line.endIndex, line[afterDot] == " " else { return nil }
        let start = line.index(after: afterDot)
        guard start <= line.endIndex else { return nil }
        return String(line[start...])
    }
}

struct MarkdownSummaryText: View {
    let content: String
    var maxBlocks: Int?

    private var blocks: [MarkdownBlock] {
        let all = MarkdownSummaryFormatter.blocks(from: content)
        guard let maxBlocks, all.count > maxBlocks else { return all }
        return Array(all.prefix(maxBlocks))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NHSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .paragraph(let text):
            inlineMarkdownText(text)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.primaryBlue)
                inlineMarkdownText(text)
            }
        }
    }

    @ViewBuilder
    private func inlineMarkdownText(_ text: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
