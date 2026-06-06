# HealthLongi - AI Assistant Guide

## Project Overview

Vitals & Mind is an iOS health risk assessment app that combines HealthKit data with mental health assessments to calculate comprehensive health risk profiles. Built with SwiftUI, SwiftData, and integrates with GLM API for AI-powered insights.

## Architecture

Clean Architecture with clear separation of concerns:

```
HealthLongi/
├── App/                    # Entry point, dependency injection, root view
│   ├── HealthLongiApp.swift         # App entry point, SwiftData setup
│   ├── AppDependencies.swift        # Service DI container
│   └── RootView.swift               # Navigation root
├── Config/                 # App configuration
│   └── AppConfig.swift              # GLM API key configuration
├── Core/                   # Shared core components
│   ├── Models/            # Domain models (SwiftData entities)
│   ├── Navigation/        # Routing with AppRoute enum
│   ├── Protocols/         # Service abstractions
│   ├── Resources/         # NHS links, demo seeder
│   └── Theme/             # NHS-themed UI components
├── Features/              # Feature modules (self-contained)
│   ├── AI/               # GLMService, GLMPrompts
│   ├── Dashboard/        # Health dashboard, domain status cards
│   ├── Onboarding/       # User demographics setup
│   ├── Questionnaires/   # PHQ-9, GAD-7 assessments
│   ├── Results/          # Risk results display
│   └── Scoring/          # RiskCalculator engine
└── Services/             # External service implementations
    ├── HealthKit/       # HealthKitManager, MockHealthDataProvider
    └── Orchestrator/    # AssessmentOrchestrator workflow
```

## Key Patterns

### Dependency Injection
All services injected via `AppDependencies`:
```swift
@Environment(\.appDependencies) var dependencies
let healthProvider = dependencies.healthDataProvider
```

### Protocol-Oriented Design
Services implement protocols for testability:
- `HealthDataProviding`: HealthKit data abstraction
- `RiskCalculating`: Risk calculation abstraction
- `AISummarizing`: AI service abstraction

### SwiftData Models
All SwiftData models marked `@Model`:
- `UserProfile`: User demographics (persisted)
- `RiskAssessment`: Assessment results (persisted)
- `AbstractedRiskProfile`: Calculated profile (computed)
- `RiskLevel`: Low/Moderate/High enum
- `MentalFlag`: Mental health status flags

### Navigation
Routing via `AppRoute` enum:
```swift
enum AppRoute {
    case onboarding
    case dashboard
    case questionnaires
    case results(AbstractedRiskProfile)
}
```

## Core Services

### HealthKitManager (`Services/HealthKit/HealthKitManager.swift`)
Reads HealthKit data:
- Weekly steps with prior week comparison
- Resting heart rate average
- Sleep hours average
- Implements `HealthDataProviding` protocol

### RiskCalculator (`Features/Scoring/RiskCalculator.swift`)
Calculates risk profiles:
- Cardiovascular risk (steps, heart rate, demographics)
- Metabolic risk (BMI, activity, demographics)
- Mental health risk (PHQ-9, GAD-7 scores)
- Returns `AbstractedRiskProfile` with risk levels

### GLMService (`Features/AI/GLMService.swift`)
AI summarization:
- Sends anonymized risk profile to GLM API
- Returns actionable health insights
- Implements `AISummarizing` protocol
- Prompts defined in `GLMPrompts.swift`

### AssessmentOrchestrator (`Services/Orchestrator/AssessmentOrchestrator.swift`)
Coordinates assessment workflow:
- Collects health data
- Runs risk calculator
- Generates AI summary
- Returns complete assessment

## Health Data Models

### UserProfile
```swift
@Model
struct UserProfile {
    var demographics: Demographics
    var onboardingCompleted: Bool
}
```

### RiskAssessment
```swift
@Model
struct RiskAssessment {
    var profile: AbstractedRiskProfile
    var timestamp: Date
    var aiSummary: AISummaryResult?
}
```

### AbstractedRiskProfile
```swift
struct AbstractedRiskProfile {
    var cardioRisk: RiskLevel
    var metabolic: RiskLevel
    var mentalHealth: MentalFlag
    var correlations: [String]
    var weeklySnapshot: WeeklyHealthSnapshot
}
```

## Questionnaires

### PHQ-9 (Depression)
9 questions, score 0-27:
- 0-4: Minimal
- 5-9: Mild
- 10-14: Moderate
- 15-19: Moderately severe
- 20-27: Severe

### GAD-7 (Anxiety)
7 questions, score 0-21:
- 0-4: Minimal
- 5-9: Mild
- 10-14: Moderate
- 15-21: Severe

## Privacy Requirements

- All health data processing must happen on-device
- Raw HealthKit data never leaves device
- Only anonymized risk profiles sent to GLM API
- User must grant explicit HealthKit permissions
- Assessment results stored locally with SwiftData

## HealthKit Integration

### Required Permissions (in Info.plist):
- `NSHealthShareUsageDescription`: "Vitals & Mind reads your steps, heart rate, and sleep to calculate on-device health scores. Raw data never leaves your device."
- `NSHealthUpdateUsageDescription`: "Vitals & Mind may save health insights locally on your device."

### Entitlements:
- HealthKit access enabled in `HealthLongi.entitlements`

## Configuration

### API Key
GLM API key configured via `Config/Secrets.xcconfig`:
```bash
GLM_API_KEY = your_key_here
```

Or set as environment variable: `GLM_API_KEY=your_key`

Accessed via `AppConfig.glmAPIKey`.

## Testing

### Unit Tests
Located in `HealthLongiTests/`:
- `RiskCalculatorTests`: Risk calculation logic
- `AbstractedRiskProfileTests`: Profile model tests

### Mock Data
Use `MockHealthDataProvider` for testing:
```swift
let mockProvider = MockHealthDataProvider()
let dependencies = AppDependencies.mock(healthDataProvider: mockProvider)
```

### Test Scenarios
Predefined scenarios in `scripts/mock_health_data.py`:
- `high_anxiety_dropping_steps`: High anxiety, declining activity
- `low_risk_active`: Healthy, active user
- `metabolic_moderate_sedentary`: Moderate metabolic risk, sedentary

## Development Guidelines

### Adding Features
1. Create feature module in `Features/`
2. Follow Clean Architecture pattern
3. Add protocol abstractions for services
4. Inject via `AppDependencies`
5. Write unit tests

### UI Development
- SwiftUI for all views
- NHSTheme for styling (NHS colors: blue, teal, red)
- MainActor for UI updates
- Async/await for async operations

### Code Style
- Protocol-oriented design
- Value types for models
- Reference types for services
- Sendable conformance for thread safety
- Clear separation of concerns

## NHS Resources

Links provided via `NHSLinks.swift`:
- Mental health services
- Heart health information
- Diabetes prevention
- Healthy weight guidance
- Emergency services (111)

Links filtered based on risk profile:
```swift
let links = NHSLinks.links(for: riskProfile)
```

## Common Tasks

### Adding New Health Metric
1. Add to `WeeklyHealthSnapshot` model
2. Update `HealthDataProviding` protocol
3. Implement in `HealthKitManager`
4. Add to `RiskCalculator` logic
5. Update `GLMPrompts` for AI context

### Adding New Questionnaire
1. Create questionnaire view in `Features/Questionnaires/`
2. Add scoring logic
3. Update `AssessmentInput` model
4. Add to `QuestionnaireFlowView`

### Updating Risk Calculation
1. Modify `RiskCalculator.swift`
2. Update scoring thresholds
3. Add unit tests for new logic
4. Update `GLMPrompts` with context

## Troubleshooting

### HealthKit Permissions Not Granted
Check `Info.plist` strings match HealthKit requirements.

### SwiftData Migration Issues
Delete app and reinstall for schema changes during development.

### GLM API Failures
Verify API key in `Config/Secrets.xcconfig` and internet connectivity.

### Mock Data Not Working
Ensure `MockHealthDataProvider` properly implements `HealthDataProviding`.

## Build Requirements

- Xcode 26.5+
- iOS 26.5+ deployment target
- Swift 5.0
- SwiftData
- HealthKit framework

## Important Notes

- App requires physical device for HealthKit integration (simulator has limited support)
- HealthKit requires explicit user permission on first launch
- GLM API requires internet connectivity
- All assessment data persists locally using SwiftData
- Risk profiles are anonymized before AI processing
- NHS links are UK-specific and may need localization

## Project-Specific Commands

### Run Unit Tests
```bash
xcodebuild test -scheme HealthLongi
```

### Generate Mock Data
```bash
python3 scripts/mock_health_data.py
```

### Clean Build
```bash
xcodebuild clean -scheme HealthLongi
```

## Current Branch Context

- Main branch: `main`
- Recent changes: Initial project setup
- Git status: Modified `project.pbxproj`
- Development team: `3FGB24BJ83`
- Bundle identifier: `com.pahlavan.HealthLongi`