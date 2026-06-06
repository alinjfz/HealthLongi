import Foundation

struct RiskCalculator: RiskCalculating {
    func calculate(input: AssessmentInput) -> ScoringResult {
        let phq9 = input.phq9Score
        let gad7 = input.gad7Score
        let metabolicScore = findriscScore(input: input)
        let cardioScore = cardioApproximationScore(input: input)
        let mentalFlag = mentalHealthFlag(phq9: phq9, gad7: gad7)
        let correlations = detectCorrelations(input: input, gad7: gad7)

        let profile = AbstractedRiskProfile(
            cardioRisk: level(for: cardioScore, moderateThreshold: 8, highThreshold: 14),
            mentalHealth: mentalFlag,
            metabolic: level(for: metabolicScore, moderateThreshold: 7, highThreshold: 11),
            correlations: correlations
        )

        return ScoringResult(
            profile: profile,
            phq9Score: phq9,
            gad7Score: gad7,
            metabolicScore: metabolicScore,
            cardioScore: cardioScore
        )
    }

    // MARK: - FINDRISC subset (simplified)

    private func findriscScore(input: AssessmentInput) -> Int {
        var score = 0
        let age = input.demographics.age

        switch age {
        case 45..<55: score += 2
        case 55..<65: score += 3
        case 65...: score += 4
        default: break
        }

        if let bmi = input.bmi {
            switch bmi {
            case 25..<30: score += 1
            case 30..<35: score += 3
            case 35...: score += 4
            default: break
            }
        }

        let activity = input.physicalActivityMinutes ?? 0
        if activity < 30 {
            score += 2
        }

        if input.weeklySteps ?? 0 < 5000 {
            score += 1
        }

        return score
    }

    // MARK: - Cardio approximation (not full QRISK3)

    private func cardioApproximationScore(input: AssessmentInput) -> Int {
        var score = 0
        let age = input.demographics.age

        switch age {
        case 40..<50: score += 2
        case 50..<60: score += 4
        case 60...: score += 6
        default: break
        }

        switch input.demographics.smokingStatus {
        case .current: score += 5
        case .former: score += 2
        case .never: break
        }

        if let hr = input.restingHeartRate, hr > 80 {
            score += 3
        } else if let hr = input.restingHeartRate, hr > 70 {
            score += 1
        }

        let activity = input.physicalActivityMinutes ?? 0
        if activity < 30 {
            score += 2
        }

        if input.demographics.sex == .male && age >= 45 {
            score += 1
        }

        return score
    }

    // MARK: - Mental health thresholds

    private func mentalHealthFlag(phq9: Int, gad7: Int) -> MentalFlag {
        if gad7 >= 15 { return .highAnxiety }
        if gad7 >= 10 { return .moderateAnxiety }
        if phq9 >= 20 { return .severeDepression }
        if phq9 >= 10 { return .moderateDepression }
        if phq9 >= 5 || gad7 >= 5 { return .mild }
        return .none
    }

    // MARK: - Correlations

    private func detectCorrelations(input: AssessmentInput, gad7: Int) -> [String] {
        var correlations: [String] = []

        if let current = input.weeklySteps,
           let prior = input.priorWeeklySteps,
           prior > 0 {
            let drop = Double(prior - current) / Double(prior)
            if drop > 0.20 && gad7 >= 10 {
                correlations.append("dropping_steps_with_high_gad7")
            }
        }

        if let sleep = input.sleepHoursAvg, sleep < 6, gad7 >= 10 {
            correlations.append("poor_sleep_with_high_anxiety")
        }

        if let sleep = input.sleepHoursAvg, sleep < 6, input.phq9Score >= 10 {
            correlations.append("poor_sleep_with_elevated_depression")
        }

        if (input.physicalActivityMinutes ?? 0) < 30 && input.phq9Score >= 10 {
            correlations.append("low_activity_with_elevated_depression")
        }

        return correlations
    }

    private func level(for score: Int, moderateThreshold: Int, highThreshold: Int) -> RiskLevel {
        if score >= highThreshold { return .high }
        if score >= moderateThreshold { return .moderate }
        return .low
    }
}
