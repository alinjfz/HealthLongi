import Foundation

struct RiskCalculator: RiskCalculating {
    func calculate(input: AssessmentInput) -> ScoringResult {
        let phq9 = input.phq9Score
        let gad7 = input.gad7Score
        let metabolicScore = findriscScore(input: input)
        let cardioScore = cardioApproximationScore(input: input)
        let mentalFlag = mentalHealthFlag(input: input)
        let correlations = detectCorrelations(input: input, gad7: gad7)

        let profile = AbstractedRiskProfile(
            cardioRisk: level(for: cardioScore, moderateThreshold: 8, highThreshold: 14),
            mentalHealth: mentalFlag,
            metabolic: level(for: metabolicScore, moderateThreshold: 7, highThreshold: 11),
            correlations: correlations,
            labSignals: input.labSignals
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

        if input.labSignals.elevatedGlucose { score += 3 }
        if input.labSignals.elevatedWaist { score += 2 }
        if input.labSignals.kidneyConcern { score += 1 }

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
        case .currentRegular, .currentOccasional, .vapingRegular, .vapingOccasional:
            score += 5
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

        if input.labSignals.elevatedLipids { score += 3 }
        if input.labSignals.elevatedBloodPressure { score += 4 }
        if input.labSignals.elevatedInflammation { score += 1 }
        if (input.auditCScore ?? 0) >= 4 { score += 2 }

        return score
    }

    // MARK: - Mental health thresholds

    private func mentalHealthFlag(input: AssessmentInput) -> MentalFlag {
        let phq9 = input.phq9Score
        let gad7 = input.gad7Score

        var flag: MentalFlag
        if gad7 >= 15 { flag = .highAnxiety }
        else if gad7 >= 10 { flag = .moderateAnxiety }
        else if phq9 >= 20 { flag = .severeDepression }
        else if phq9 >= 10 { flag = .moderateDepression }
        else if phq9 >= 5 || gad7 >= 5 { flag = .mild }
        else { flag = .none }

        if let pss = input.pss10Score, pss >= 20 {
            flag = escalateAnxiety(flag)
        }

        if let who5 = input.who5Score, who5 <= 8 {
            flag = escalateDepression(flag)
        }

        if let phq15 = input.phq15Score, phq15 >= 15 {
            flag = escalateSomatic(flag)
        } else if let phq15 = input.phq15Score, phq15 >= 10, flag == .none || flag == .mild {
            flag = .mild
        }

        return flag
    }

    private func escalateAnxiety(_ flag: MentalFlag) -> MentalFlag {
        switch flag {
        case .none, .mild: .moderateAnxiety
        case .moderateDepression: .moderateAnxiety
        case .moderateAnxiety, .highAnxiety, .severeDepression: flag
        }
    }

    private func escalateDepression(_ flag: MentalFlag) -> MentalFlag {
        switch flag {
        case .none: .mild
        case .mild: .moderateDepression
        case .moderateAnxiety: .moderateDepression
        case .moderateDepression, .severeDepression, .highAnxiety: flag
        }
    }

    private func escalateSomatic(_ flag: MentalFlag) -> MentalFlag {
        switch flag {
        case .none: .mild
        case .mild, .moderateAnxiety: .moderateDepression
        case .moderateDepression, .severeDepression, .highAnxiety: flag
        }
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

        if input.labSignals.elevatedGlucose && (input.weeklySteps ?? 0) < 5000 {
            correlations.append("elevated_glucose_with_low_activity")
        }

        if input.labSignals.elevatedLipids && (input.physicalActivityMinutes ?? 0) < 30 {
            correlations.append("elevated_lipids_with_sedentary_lifestyle")
        }

        if input.labSignals.elevatedBloodPressure,
           let hr = input.restingHeartRate, hr > 80 {
            correlations.append("elevated_bp_with_high_resting_hr")
        }

        if input.labSignals.lowVitamins,
           let sleep = input.sleepHoursAvg, sleep < 6 {
            correlations.append("low_nutrients_with_poor_sleep")
        }

        if (input.pss10Score ?? 0) >= 14,
           let sleep = input.sleepHoursAvg, sleep < 6 {
            correlations.append("high_stress_with_poor_sleep")
        }

        return correlations
    }

    private func level(for score: Int, moderateThreshold: Int, highThreshold: Int) -> RiskLevel {
        if score >= highThreshold { return .high }
        if score >= moderateThreshold { return .moderate }
        return .low
    }
}
