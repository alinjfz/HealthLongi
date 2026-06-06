import Foundation

protocol OnDeviceHealthAIProviding: Sendable {
    func explainSignal(_ signal: HealthSignal, context: PersonalHealthContext?) async -> String
    func generateWeeklyInsight(from context: PersonalHealthContext) async -> String
    func suggestGPQuestions(from context: PersonalHealthContext) async -> [String]
}

extension OnDeviceHealthAIProviding {
    func explainSignal(_ signal: HealthSignal) async -> String {
        await explainSignal(signal, context: nil)
    }
}
