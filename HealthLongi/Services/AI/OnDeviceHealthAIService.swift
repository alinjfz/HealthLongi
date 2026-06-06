import Foundation
import FoundationModels

struct OnDeviceHealthAIService: OnDeviceHealthAIProviding {
    private let model = SystemLanguageModel.default

    func explainSignal(_ signal: HealthSignal, context: PersonalHealthContext?) async -> String {
        let fallback = OnDeviceHealthAITemplates.explainSignal(signal)
        guard model.isAvailable else { return fallback }

        let prompt = """
        Explain this health signal in plain English, NHS tone, max 80 words.
        Never name diseases or recommend medications.
        Only reference facts in the signal evidence.
        For discuss-with-GP severity you may suggest considering a GP conversation.

        Signal: \(signal.title)
        Detail: \(signal.detail)
        Evidence: \(signal.evidence.map { "\($0.label)=\($0.value)" }.joined(separator: ", "))
        """

        return await generate(prompt: prompt, fallback: fallback, maxWords: 80)
    }

    func generateWeeklyInsight(from context: PersonalHealthContext) async -> String {
        let fallback = OnDeviceHealthAITemplates.weeklyInsight(from: context)
        guard model.isAvailable else { return fallback }

        let contextJSON = (try? String(data: JSONEncoder().encode(context), encoding: .utf8)) ?? "{}"
        let prompt = """
        Write a weekly wellbeing insight in plain English, NHS tone, max 120 words.
        Never name diseases or recommend medications. Only use facts from this JSON:
        \(contextJSON)
        """

        return await generate(prompt: prompt, fallback: fallback, maxWords: 120)
    }

    func suggestGPQuestions(from context: PersonalHealthContext) async -> [String] {
        let fallback = OnDeviceHealthAITemplates.suggestGPQuestions(from: context)
        guard model.isAvailable else { return fallback }

        let prompt = """
        Suggest up to 5 questions for a GP visit based on active signals.
        Return one question per line. No diagnoses or medication names.
        Signals: \(context.activeSignals.map(\.title).joined(separator: "; "))
        """

        guard let text = try? await sessionResponse(prompt: prompt) else { return fallback }
        let questions = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-") }
            .map { $0.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression) }
            .filter { !AISafetyFilter.isBlocked($0) }

        return questions.isEmpty ? fallback : Array(questions.prefix(5))
    }

    private func generate(prompt: String, fallback: String, maxWords: Int) async -> String {
        guard let text = try? await sessionResponse(prompt: prompt) else { return fallback }
        let trimmed = truncate(text, maxWords: maxWords)
        return AISafetyFilter.sanitize(trimmed, fallback: fallback)
    }

    private func sessionResponse(prompt: String) async throws -> String {
        let instructions = """
        You are a supportive NHS-style health companion. Use plain English.
        Never diagnose. Never recommend specific medications.
        """
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    private func truncate(_ text: String, maxWords: Int) -> String {
        let words = text.split(separator: " ")
        guard words.count > maxWords else { return text }
        return words.prefix(maxWords).joined(separator: " ") + "…"
    }
}

/// Preview and test fallback when Apple Intelligence is unavailable.
struct TemplateOnDeviceHealthAIService: OnDeviceHealthAIProviding {
    func explainSignal(_ signal: HealthSignal, context: PersonalHealthContext?) async -> String {
        OnDeviceHealthAITemplates.explainSignal(signal)
    }

    func generateWeeklyInsight(from context: PersonalHealthContext) async -> String {
        OnDeviceHealthAITemplates.weeklyInsight(from: context)
    }

    func suggestGPQuestions(from context: PersonalHealthContext) async -> [String] {
        OnDeviceHealthAITemplates.suggestGPQuestions(from: context)
    }
}
