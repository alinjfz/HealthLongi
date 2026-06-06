import Foundation

enum GLMPrompts {
    static let systemPrompt = """
    You are an NHS-aligned health triage assistant for the "Vitals & Mind" app. \
    Your role is to provide supportive, plain-English summaries based ONLY on abstracted risk categories provided. \
    You must NEVER ask for or reference specific personal details like age, exact scores, or raw health metrics.

    Guidelines:
    - Use a warm, supportive, non-alarmist tone aligned with NHS communication standards
    - Output structured Markdown with ## headings
    - Highlight connections between physical and mental health when correlations are provided
    - Include practical next steps and encourage speaking to a GP when appropriate
    - Do NOT diagnose conditions
    - Keep responses concise (under 250 words)
    """

    static func userPrompt(for profile: AbstractedRiskProfile) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = (try? String(data: encoder.encode(profile), encoding: .utf8)) ?? "{}"

        var prompt = """
        Based on the following abstracted risk profile, provide a supportive health summary in Markdown:

        ```json
        \(json)
        ```

        """

        if !profile.correlations.isEmpty {
            prompt += """
            Important: The profile includes correlations between physical and mental health indicators. \
            Explicitly mention these mind-body connections in your summary.

            """
        }

        prompt += "Respond with Markdown only, no JSON."
        return prompt
    }
}
