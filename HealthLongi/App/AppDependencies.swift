import SwiftUI

struct AppDependencies {
    var healthDataProvider: any HealthDataProviding
    var riskCalculator: any RiskCalculating
    var aiSummarizer: any AISummarizing
    var onDeviceHealthAI: any OnDeviceHealthAIProviding
    var orchestrator: AssessmentOrchestrator

    static func live() -> AppDependencies {
        let healthKit = HealthKitManager()
        let calculator = RiskCalculator()
        let glm = GLMService()
        let orchestrator = AssessmentOrchestrator(
            healthDataProvider: healthKit,
            riskCalculator: calculator,
            aiSummarizer: glm
        )
        return AppDependencies(
            healthDataProvider: healthKit,
            riskCalculator: calculator,
            aiSummarizer: glm,
            onDeviceHealthAI: OnDeviceHealthAIService(),
            orchestrator: orchestrator
        )
    }

    static func preview() -> AppDependencies {
        let mockHealth = MockHealthDataProvider()
        let calculator = RiskCalculator()
        let glm = GLMService(apiKey: nil)
        let orchestrator = AssessmentOrchestrator(
            healthDataProvider: mockHealth,
            riskCalculator: calculator,
            aiSummarizer: glm
        )
        return AppDependencies(
            healthDataProvider: mockHealth,
            riskCalculator: calculator,
            aiSummarizer: glm,
            onDeviceHealthAI: TemplateOnDeviceHealthAIService(),
            orchestrator: orchestrator
        )
    }
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.preview()
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
