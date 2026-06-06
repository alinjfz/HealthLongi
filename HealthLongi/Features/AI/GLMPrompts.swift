import Foundation

enum GLMPrompts {
    static let systemPrompt = """
    You write brief health summaries for the Vitals & Mind app. Sound like a kind, calm NHS nurse \
    talking to a friend — warm, human, and easy to understand.

    Rules:
    - Use plain everyday English. No medical jargon, no technical labels, no numbers or scores.
    - Maximum 90 words. Shorter is better.
    - Write exactly 2 short paragraphs separated by a blank line.
    - Paragraph 1: what stands out, in simple words anyone can follow.
    - Paragraph 2: one gentle, practical suggestion — a small step they could try this week.
    - You may add up to 2 short bullet points after paragraph 2 if helpful. No headings or titles.
    - Never diagnose. Do not use words like "moderate", "elevated", or "risk profile".
    - Only mention speaking to a GP if something genuinely needs attention — keep it light, not alarming.
    """

    static func userPrompt(for profile: AbstractedRiskProfile) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = (try? String(data: encoder.encode(profile), encoding: .utf8)) ?? "{}"

        var prompt = """
        Write a brief, human summary for this person. No title. No ## headings. Under 90 words.

        Risk profile (for your reference only — do not repeat these labels verbatim):
        ```json
        \(json)
        ```

        """

        if !profile.correlations.isEmpty {
            prompt += """
            Their physical and mental health may be linked (e.g. sleep, activity, mood). \
            Mention that connection in one simple, reassuring sentence if relevant.

            """
        }

        prompt += "Respond with plain Markdown only (paragraphs and optional bullets). No JSON."
        return prompt
    }

    static func fallbackText(for profile: AbstractedRiskProfile) -> String {
        var lines: [String] = []

        switch profile.mentalHealth {
        case .highAnxiety, .moderateAnxiety:
            lines.append("You've been carrying a bit more worry than usual — that's really common, and it doesn't mean you're failing.")
        case .severeDepression, .moderateDepression:
            lines.append("Your mood scores suggest you've been having a tougher time lately. Please be gentle with yourself.")
        case .mild:
            lines.append("Things look mostly okay, with a few small bumps — nothing unusual.")
        case .none:
            lines.append("Your mood and anxiety scores look fairly steady right now.")
        }

        if profile.cardioRisk == .high || profile.metabolic == .high {
            lines.append("Your activity and heart-related signals could use a little attention — small daily changes can help.")
        } else if profile.cardioRisk == .moderate || profile.metabolic == .moderate {
            lines.append("A few physical health signals are worth keeping an eye on, but there's room to improve gradually.")
        }

        if profile.correlations.contains("dropping_steps_with_high_gad7") {
            lines.append("When we're anxious, moving less is very common — a short daily walk can help both body and mind.")
        } else if profile.correlations.contains("poor_sleep_with_high_anxiety") {
            lines.append("Poor sleep and worry often go hand in hand — a regular wind-down routine may ease both.")
        }

        let action: String
        if profile.mentalHealth == .severeDepression || profile.mentalHealth == .highAnxiety {
            action = "If things feel heavy, talk to your GP — you don't have to sort this out alone."
        } else {
            action = "Try one small step this week, like a 10-minute walk or going to bed 30 minutes earlier."
        }

        let opening = lines.prefix(2).joined(separator: " ")
        return "\(opening)\n\n\(action)"
    }
}
