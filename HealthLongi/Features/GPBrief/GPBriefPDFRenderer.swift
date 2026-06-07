import UIKit

enum GPBriefPDFRenderer {
    static func render(_ brief: GPVisitBrief) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let margin: CGFloat = 40
        var y = margin

        return renderer.pdfData { context in
            context.beginPage()
            y = drawTitle("GP Visit Brief", at: y, margin: margin, pageRect: pageRect, context: context)

            y = drawSection("1. Reason for visit", body: brief.reasonForVisit, y: y, margin: margin, pageRect: pageRect, context: context)

            let topics = brief.discussionTopics.map { "• \($0.title) (\($0.severity)): \($0.evidenceSummary)" }.joined(separator: "\n")
            y = drawSection("2. Key discussion topics", body: topics.isEmpty ? "None recorded." : topics, y: y, margin: margin, pageRect: pageRect, context: context)

            let screenings = brief.screeningScores.map { "• \($0.kind.title): \($0.score)/\($0.maxScore) — \($0.band)" }.joined(separator: "\n")
            y = drawSection("3. Screening scores", body: screenings.isEmpty ? "None completed." : screenings, y: y, margin: margin, pageRect: pageRect, context: context)

            let measures = physicalMeasuresText(brief.physicalMeasures)
            y = drawSection("4. Physical measures", body: measures, y: y, margin: margin, pageRect: pageRect, context: context)

            let labs = brief.abnormalLabs.map(\.displaySummary).joined(separator: "\n")
            y = drawSection("5. Labs (out of range)", body: labs.isEmpty ? "None flagged." : labs, y: y, margin: margin, pageRect: pageRect, context: context)

            let questions = brief.suggestedQuestions.map { "• \($0)" }.joined(separator: "\n")
            y = drawSection("6. Suggested GP questions", body: questions, y: y, margin: margin, pageRect: pageRect, context: context)

            let footer = "\(brief.dataSourcesNote)\n\n\(brief.disclaimer)"
            _ = drawSection("7. Data sources & limitations", body: footer, y: y, margin: margin, pageRect: pageRect, context: context)
        }
    }

    private static func physicalMeasuresText(_ measures: LifestyleSnapshot) -> String {
        var lines: [String] = []
        if measures.averageDailySteps > 0 { lines.append("Daily steps: \(measures.averageDailySteps)") }
        if let rhr = measures.averageRestingHeartRate { lines.append("Resting HR: \(Int(rhr)) bpm") }
        if let sleep = measures.averageSleepHours { lines.append("Sleep: \(SleepDurationFormatting.format(hours: sleep))") }
        if let bmi = measures.bmi { lines.append("BMI: \(String(format: "%.1f", bmi))") }
        return lines.isEmpty ? "No HealthKit averages available." : lines.joined(separator: "\n")
    }

    private static func drawTitle(
        _ title: String,
        at startY: CGFloat,
        margin: CGFloat,
        pageRect: CGRect,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor(red: 0.0, green: 0.29, blue: 0.61, alpha: 1.0)
        ]
        let rect = CGRect(x: margin, y: startY, width: pageRect.width - margin * 2, height: 30)
        title.draw(in: rect, withAttributes: attrs)
        return startY + 36
    }

    private static func drawSection(
        _ heading: String,
        body: String,
        y startY: CGFloat,
        margin: CGFloat,
        pageRect: CGRect,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var y = startY
        let headingAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor(red: 0.0, green: 0.29, blue: 0.61, alpha: 1.0)
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]

        if y > pageRect.height - 80 {
            context.beginPage()
            y = margin
        }

        let headingRect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 18)
        heading.draw(in: headingRect, withAttributes: headingAttrs)
        y += 20

        let bodyHeight = bodyHeight(for: body, width: pageRect.width - margin * 2, font: UIFont.systemFont(ofSize: 11))
        let bodyRect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: bodyHeight)
        body.draw(in: bodyRect, withAttributes: bodyAttrs)
        return y + bodyHeight + 14
    }

    private static func bodyHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let rect = CGSize(width: width, height: .greatestFiniteMagnitude)
        return text.boundingRect(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height + 4
    }
}
