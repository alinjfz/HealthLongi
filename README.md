# HealthLongi

**Vitals & Mind** - iOS health risk assessment app using HealthKit data and AI analysis.

## Overview

Vitals & Mind is a privacy-focused iOS app that reads health data from Apple Health (steps, heart rate, sleep) and combines it with mental health assessments to calculate comprehensive health risk profiles. All data processing happens on-device, with raw health data never leaving the device.

## Features

- **HealthKit Integration**: Reads steps, heart rate, and sleep data
- **Mental Health Questionnaires**: PHQ-9 (depression) and GAD-7 (anxiety) assessments
- **Risk Assessment**: Calculates cardiovascular, metabolic, and mental health risk levels
- **AI-Powered Summaries**: Uses GLM API for personalized health insights
- **NHS Integration**: Provides relevant NHS resources based on risk profile
- **Dashboard**: Visualizes health status and weekly trends
- **Onboarding**: User demographics and profile setup
- **Privacy-First**: Health data processed on-device, raw data never leaves device

## Architecture

### Clean Architecture

```
HealthLongi/
├── App/                    # App entry point and dependencies
│   ├── HealthLongiApp.swift
│   ├── AppDependencies.swift
│   └── RootView.swift
├── Config/                 # App configuration
│   └── AppConfig.swift
├── Core/                   # Shared core components
│   ├── Models/            # Domain models
│   ├── Navigation/        # Routing
│   ├── Protocols/         # Service protocols
│   ├── Resources/         # Shared resources (NHS links, demo data)
│   └── Theme/             # UI theme components
├── Features/              # Feature modules
│   ├── AI/               # AI services and prompts
│   ├── Dashboard/        # Health dashboard
│   ├── Onboarding/       # User onboarding flow
│   ├── Questionnaires/   # PHQ-9 and GAD-7 assessments
│   ├── Results/          # Risk results display
│   └── Scoring/          # Risk calculation engine
└── Services/             # External services
    ├── HealthKit/       # HealthKit data access
    └── Orchestrator/    # Assessment coordination
```

### Key Components

**Models:**
- `UserProfile`: User demographics and preferences
- `RiskAssessment`: Stored assessment results
- `AbstractedRiskProfile`: Calculated risk profile
- `RiskLevel`: Low/Moderate/High risk classification
- `MentalFlag`: Mental health status flags
- `WeeklyHealthSnapshot`: Weekly health data summary

**Services:**
- `HealthKitManager`: HealthKit data provider
- `MockHealthDataProvider`: Testing data provider
- `GLMService`: AI summarization service
- `RiskCalculator`: Risk assessment engine
- `AssessmentOrchestrator`: Assessment workflow coordinator

**Protocols:**
- `HealthDataProviding`: Health data source abstraction
- `RiskCalculating`: Risk calculation abstraction
- `AISummarizing`: AI service abstraction

## Tech Stack

- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Health Data**: HealthKit
- **Target**: iOS 26.5+
- **Build**: Xcode 26.5

## Setup

### Prerequisites

- Xcode 26.5+
- iOS 26.5+ device or simulator
- Apple Developer account (for HealthKit permissions)
- GLM API key

### Installation

1. Clone repository:
```bash
git clone https://github.com/yourusername/HealthLongi.git
cd HealthLongi
```

2. Open in Xcode:
```bash
open HealthLongi.xcodeproj
```

3. Configure API key:
- Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig`
- Add your GLM API key:
```bash
GLM_API_KEY = your_key_here
```
Or set as environment variable: `GLM_API_KEY=your_key`

4. Build and run:
- Select your device/simulator
- Press ⌘R to build and run

### HealthKit Permissions

The app requires the following HealthKit permissions:
- Steps (QuantityType)
- Heart Rate (QuantityType)
- Sleep Analysis (CategoryType)

## Usage

### First-Time Setup

1. Launch app
2. Grant HealthKit permissions
3. Complete onboarding (demographics)
4. Allow 24 hours for health data collection
5. Complete mental health questionnaires (PHQ-9, GAD-7)
6. View results and AI-powered insights

### Dashboard

- View current health status cards
- Monitor weekly trends
- Access NHS resources based on risk profile
- Complete new assessments

### Risk Assessment Process

1. Collect weekly health data (steps, heart rate, sleep)
2. Complete PHQ-9 and GAD-7 questionnaires
3. Input metabolic metrics (BMI, activity level)
4. Calculate risk profile using `RiskCalculator`
5. Generate AI summary using `GLMService`
6. Display results with relevant NHS links

## Privacy

- **On-Device Processing**: All health data processing happens on-device
- **No Data Upload**: Raw health data never leaves device
- **Local Storage**: Assessment results stored locally using SwiftData
- **AI Privacy**: Only anonymized risk profiles sent to GLM API
- **User Control**: Users can revoke HealthKit access at any time

## Testing

### Unit Tests

```bash
# Run all tests
xcodebuild test -scheme HealthLongi

# Run specific test
xcodebuild test -scheme HealthLongi -only-testing:HealthLongiTests/RiskCalculatorTests
```

### Mock Data

Generate mock health data for testing:
```bash
python3 scripts/mock_health_data.py
```

### Test Scenarios

The app includes predefined test scenarios:
- `high_anxiety_dropping_steps`: High anxiety with declining activity
- `low_risk_active`: Healthy, active user
- `metabolic_moderate_sedentary`: Moderate metabolic risk, sedentary

## Development

### Adding New Features

1. Create feature module in `Features/`
2. Follow Clean Architecture pattern
3. Implement dependency injection via `AppDependencies`
4. Add protocol abstractions for services
5. Write unit tests in `HealthLongiTests/`

### Code Style

- SwiftUI for all UI components
- SwiftData for persistence
- Protocol-oriented design
- Async/await for async operations
- MainActor for UI updates

### Dependency Injection

Use `AppDependencies` for service injection:
```swift
@Environment(\.appDependencies) var dependencies
let healthDataProvider = dependencies.healthDataProvider
```

## HealthKit Integration

The app uses `HealthKitManager` to read:
- **Steps**: Weekly step count with prior week comparison
- **Heart Rate**: Resting heart rate average
- **Sleep**: Average sleep hours per night

Permissions are requested on first launch and stored in `HealthLongi.entitlements`.

## AI Integration

### GLM API

The app uses GLM API for health summaries:
- Configured via `GLM_API_KEY` in Secrets.xcconfig
- Prompts defined in `GLMPrompts.swift`
- Results cached in `AISummaryResult` model

### Prompt Engineering

Prompts follow these principles:
- Anonymize health data before sending
- Focus on actionable insights
- Include NHS resource recommendations
- Keep responses concise and clear

## NHS Resources

The app provides NHS links based on risk profile:
- Mental health services
- Heart health information
- Diabetes prevention
- Healthy weight guidance
- Emergency services (111)

## Contributing

1. Fork repository
2. Create feature branch
3. Follow existing code style
4. Add tests for new features
5. Submit pull request

## License

[Add your license here]

## Credits

Built with:
- SwiftUI and SwiftData
- HealthKit framework
- GLM API
- NHS health resources

## Support

For issues and questions:
- GitHub Issues: [repository link]
- Email: [support email]

---

**Note**: This app is for informational purposes only and does not replace professional medical advice. Always consult with healthcare professionals for health concerns.