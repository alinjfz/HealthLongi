import SwiftUI

struct HealthKitDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let metric: HealthKitMetric
    let snapshot: WeeklyHealthSnapshot
    var availability: HealthKitMetricAvailability = .available

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if availability.isInteractive {
                        valueCard
                        contextCard
                        aboutCard
                    } else {
                        unavailableCard
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle(metric.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Unavailable Card

    private var unavailableCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.largeTitle)
                .foregroundStyle(NHSTheme.textSecondary)

            Text(metric.title)
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)

            Text(availability.tooltipMessage)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
                .multilineTextAlignment(.center)

            if availability == .noData {
                Text("This metric is read from Apple Health on your device.")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .nhsCard()
    }

    // MARK: - Value Card

    private var valueCard: some View {
        VStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.largeTitle)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text(formattedValue)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)

            Text(metric.unitLabel)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            if let trend = trendText {
                Label(trend, systemImage: trendIcon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(trendColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(trendColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .nhsCard()
    }

    // MARK: - Context Card

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What This Means")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text(contextDescription)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            if let range = healthyRange {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text(range)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textPrimary)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    // MARK: - About Card

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Source")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Label("Collected automatically from Apple Health", systemImage: "heart.text.square")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            Label("7-day average from your device sensors", systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            Label("Last updated: \(snapshot.fetchedAt.formatted())", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    // MARK: - Computed Properties

    private var rawValue: Double? {
        switch metric {
        case .steps: return Double(snapshot.averageDailySteps)
        case .restingHeartRate: return snapshot.averageRestingHeartRate
        case .sleep: return snapshot.averageSleepHours
        case .activeEnergy: return snapshot.activeEnergyBurned
        case .distance: return snapshot.distanceWalkingRunning
        case .hrv: return snapshot.heartRateVariability
        case .oxygenSaturation: return snapshot.oxygenSaturation
        case .bodyMass: return snapshot.bodyMass
        case .height: return snapshot.height.map { $0 * 100 } // show cm
        case .bodyFat: return snapshot.bodyFatPercentage
        case .mindfulMinutes: return snapshot.mindfulMinutes
        }
    }

    private var formattedValue: String {
        guard let value = rawValue else { return "—" }
        switch metric {
        case .steps: return "\(Int(value))"
        case .restingHeartRate: return String(format: "%.0f", value)
        case .sleep: return String(format: "%.1f", value)
        case .activeEnergy: return String(format: "%.0f", value)
        case .distance: return String(format: "%.1f", value)
        case .hrv: return String(format: "%.0f", value)
        case .oxygenSaturation: return String(format: "%.0f", value)
        case .bodyMass: return String(format: "%.1f", value)
        case .height: return String(format: "%.0f", value)
        case .bodyFat: return String(format: "%.1f", value)
        case .mindfulMinutes: return String(format: "%.0f", value)
        }
    }

    private var valueColor: Color {
        switch metric {
        case .steps: return snapshot.averageDailySteps >= 7000 ? .green : (snapshot.averageDailySteps >= 4000 ? .orange : .red)
        case .restingHeartRate:
            guard let hr = snapshot.averageRestingHeartRate else { return NHSTheme.textPrimary }
            return hr <= 70 ? .green : (hr <= 80 ? .orange : .red)
        case .sleep:
            guard let s = snapshot.averageSleepHours else { return NHSTheme.textPrimary }
            return (7...9).contains(s) ? .green : (s >= 6 ? .orange : .red)
        case .activeEnergy:
            guard let e = snapshot.activeEnergyBurned else { return NHSTheme.textPrimary }
            return e >= 400 ? .green : (e >= 200 ? .orange : .red)
        case .distance: return NHSTheme.primaryBlue
        case .hrv:
            guard let h = snapshot.heartRateVariability else { return NHSTheme.textPrimary }
            return h >= 40 ? .green : (h >= 25 ? .orange : .red)
        case .oxygenSaturation:
            guard let o = snapshot.oxygenSaturation else { return NHSTheme.textPrimary }
            return o >= 95 ? .green : (o >= 90 ? .orange : .red)
        case .bodyMass: return NHSTheme.primaryBlue
        case .height: return NHSTheme.primaryBlue
        case .bodyFat:
            guard let bf = snapshot.bodyFatPercentage else { return NHSTheme.textPrimary }
            return bf <= 24 ? .green : (bf <= 32 ? .orange : .red)
        case .mindfulMinutes:
            guard let m = snapshot.mindfulMinutes else { return NHSTheme.textPrimary }
            return m >= 10 ? .green : (m >= 5 ? .orange : .red)
        }
    }

    private var trendText: String? {
        switch metric {
        case .steps:
            guard let prior = snapshot.priorAverageDailySteps, prior > 0 else { return nil }
            let change = Double(snapshot.averageDailySteps - prior) / Double(prior) * 100
            return formatTrend(change: change, suffix: "vs last week")
        default: return nil
        }
    }

    private var trendIcon: String {
        guard let prior = snapshot.priorAverageDailySteps, prior > 0 else { return "minus" }
        let change = Double(snapshot.averageDailySteps - prior) / Double(prior) * 100
        if change > 2 { return "arrow.up.right" }
        if change < -2 { return "arrow.down.right" }
        return "arrow.right"
    }

    private var trendColor: Color {
        guard let prior = snapshot.priorAverageDailySteps, prior > 0 else { return .gray }
        let change = Double(snapshot.averageDailySteps - prior) / Double(prior) * 100
        if change > 2 { return .green }
        if change < -2 { return .orange }
        return .gray
    }

    private func formatTrend(change: Double, suffix: String) -> String {
        if change > 0 {
            return String(format: "+%.0f%% %@", change, suffix)
        } else {
            return String(format: "%.0f%% %@", change, suffix)
        }
    }

    private var healthyRange: String? {
        switch metric {
        case .steps: return "Healthy: 7,000–10,000 steps/day"
        case .restingHeartRate: return "Healthy: 60–70 bpm"
        case .sleep: return "Healthy: 7–9 hours/night (NHS)"
        case .activeEnergy: return "Active: 400+ kcal/day"
        case .hrv: return "Higher is generally better; ≥40 ms is good"
        case .oxygenSaturation: return "Normal: 95–100%"
        case .bodyFat: return "Healthy range: 10–24% (varies by sex/age)"
        case .mindfulMinutes: return "Recommended: 10+ minutes/day"
        default: return nil
        }
    }

    private var contextDescription: String {
        switch metric {
        case .steps:
            return "Daily step count is a key indicator of physical activity. Regular walking reduces cardiovascular risk, improves mood, and supports metabolic health."
        case .restingHeartRate:
            return "Resting heart rate reflects cardiovascular fitness. A lower resting HR typically indicates better heart efficiency and fitness."
        case .sleep:
            return "This is objective sleep time logged in Apple Health from your iPhone or Apple Watch — different from the subjective Sleep Quality Check-in questionnaire. Sleep duration is closely linked to mental health and metabolic regulation. The NHS recommends 7–9 hours for adults."
        case .activeEnergy:
            return "Active energy measures calories burned through physical activity beyond your basal metabolic rate. Higher values indicate a more active lifestyle."
        case .distance:
            return "Walking and running distance is tracked via your device's motion sensors. It complements step count as a measure of daily activity level."
        case .hrv:
            return "Heart rate variability (HRV) measures the variation in time between heartbeats. Higher HRV generally indicates better cardiovascular fitness and stress resilience."
        case .oxygenSaturation:
            return "Blood oxygen saturation (SpO₂) measures how much oxygen your blood carries. Values below 95% may warrant medical attention."
        case .bodyMass:
            return "Body weight is tracked from Apple Health. Combined with height, it's used to calculate BMI — a screening tool for metabolic risk."
        case .height:
            return "Height is used alongside weight to calculate your BMI. This value is fetched once from Apple Health."
        case .bodyFat:
            return "Body fat percentage provides a more accurate measure of body composition than BMI alone. It's tracked via compatible scales or Apple Watch."
        case .mindfulMinutes:
            return "Mindful minutes track time spent in mindfulness or breathing exercises. Regular practice is associated with reduced anxiety and improved wellbeing."
        }
    }
}

// MARK: - HealthKit Metric Enum

enum HealthKitMetric: String, Identifiable, CaseIterable {
    case steps
    case restingHeartRate
    case sleep
    case activeEnergy
    case distance
    case hrv
    case oxygenSaturation
    case bodyMass
    case height
    case bodyFat
    case mindfulMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: "Daily Steps"
        case .restingHeartRate: "Resting Heart Rate"
        case .sleep: "Sleep Duration"
        case .activeEnergy: "Active Energy"
        case .distance: "Walking & Running Distance"
        case .hrv: "Heart Rate Variability"
        case .oxygenSaturation: "Blood Oxygen"
        case .bodyMass: "Body Weight"
        case .height: "Height"
        case .bodyFat: "Body Fat"
        case .mindfulMinutes: "Mindful Minutes"
        }
    }

    var subtitle: String {
        switch self {
        case .steps: "Weekly average from Apple Health"
        case .restingHeartRate: "Weekly average from Apple Health"
        case .sleep: "Average hours from Apple Health"
        case .activeEnergy: "Weekly average from Apple Health"
        case .distance: "Weekly average from Apple Health"
        case .hrv: "Weekly average from Apple Health"
        case .oxygenSaturation: "Weekly average from Apple Health"
        case .bodyMass: "Latest from Apple Health"
        case .height: "Latest from Apple Health"
        case .bodyFat: "Latest from Apple Health"
        case .mindfulMinutes: "Weekly average from Apple Health"
        }
    }

    var icon: String {
        switch self {
        case .steps: "figure.walk"
        case .restingHeartRate: "heart.fill"
        case .sleep: "applewatch"
        case .activeEnergy: "flame.fill"
        case .distance: "point.topleft.down.to.point.bottomright.curvepath"
        case .hrv: "waveform.path.ecg"
        case .oxygenSaturation: "lungs.fill"
        case .bodyMass: "scalemass.fill"
        case .height: "ruler"
        case .bodyFat: "figure.scale"
        case .mindfulMinutes: "brain.head.profile"
        }
    }

    var unitLabel: String {
        switch self {
        case .steps: "steps/day"
        case .restingHeartRate: "bpm"
        case .sleep: "hours/night"
        case .activeEnergy: "kcal/day"
        case .distance: "km/day"
        case .hrv: "ms"
        case .oxygenSaturation: "%"
        case .bodyMass: "kg"
        case .height: "cm"
        case .bodyFat: "%"
        case .mindfulMinutes: "min/day"
        }
    }

    /// Short formatted display of the value from a snapshot
    func shortDisplay(from snapshot: WeeklyHealthSnapshot, availability: HealthKitMetricAvailability) -> String {
        guard availability == .available else { return availability.displayValue }
        switch self {
        case .steps: return "\(snapshot.averageDailySteps)"
        case .restingHeartRate: return snapshot.averageRestingHeartRate.map { String(format: "%.0f", $0) } ?? "—"
        case .sleep: return snapshot.averageSleepHours.map { String(format: "%.1f", $0) } ?? "—"
        case .activeEnergy: return snapshot.activeEnergyBurned.map { String(format: "%.0f", $0) } ?? "—"
        case .distance: return snapshot.distanceWalkingRunning.map { String(format: "%.1f", $0) } ?? "—"
        case .hrv: return snapshot.heartRateVariability.map { String(format: "%.0f", $0) } ?? "—"
        case .oxygenSaturation: return snapshot.oxygenSaturation.map { String(format: "%.0f%%", $0) } ?? "—"
        case .bodyMass: return snapshot.bodyMass.map { String(format: "%.1f", $0) } ?? "—"
        case .height: return snapshot.height.map { String(format: "%.0f cm", $0 * 100) } ?? "—"
        case .bodyFat: return snapshot.bodyFatPercentage.map { String(format: "%.1f%%", $0) } ?? "—"
        case .mindfulMinutes: return snapshot.mindfulMinutes.map { String(format: "%.0f", $0) } ?? "—"
        }
    }

    /// Legacy helper for views that do not track availability.
    func shortDisplay(from snapshot: WeeklyHealthSnapshot) -> String {
        let availability = HealthKitMetricAvailability.availability(
            for: self,
            snapshot: snapshot,
            isHealthDataAvailable: true
        )
        return shortDisplay(from: snapshot, availability: availability)
    }
}

#Preview {
    HealthKitDetailView(metric: .steps, snapshot: .empty)
}
