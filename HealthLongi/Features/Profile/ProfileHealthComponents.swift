import SwiftUI

struct ProfileHealthMetricRow: View {
    let metric: ProfileHealthMetric
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(NHSTheme.lightBlue)
                        .frame(width: 44, height: 44)
                    Image(systemName: metric.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(NHSTheme.primaryBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)

                    Text(metric.value)
                        .font(.headline)
                        .foregroundStyle(metric.value == "—" ? NHSTheme.textSecondary : NHSTheme.textPrimary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    SourceBadge(source: metric.source)

                    if metric.allowsManualEntry {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(!metric.allowsManualEntry)
    }
}

struct SourceBadge: View {
    let source: HealthMetricSource

    var body: some View {
        Label(source.label, systemImage: source.icon)
            .font(.caption2.weight(.medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch source {
        case .healthKit: NHSTheme.primaryBlue
        case .manual: .orange
        case .unavailable: NHSTheme.textSecondary
        }
    }

    private var background: Color {
        switch source {
        case .healthKit: NHSTheme.lightBlue
        case .manual: Color.orange.opacity(0.12)
        case .unavailable: NHSTheme.lightBlue.opacity(0.5)
        }
    }
}

struct ProfileHealthSectionCard: View {
    let group: ProfileHealthGroup
    let onMetricTap: (ProfileHealthMetric) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(group.title, systemImage: group.icon)
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            VStack(spacing: 12) {
                ForEach(group.metrics) { metric in
                    ProfileHealthMetricRow(metric: metric) {
                        onMetricTap(metric)
                    }

                    if metric.id != group.metrics.last?.id {
                        Divider()
                    }
                }
            }
        }
        .nhsCard()
    }
}

struct ProfileHeaderCard: View {
    let profile: UserProfile
    let healthKitAvailable: Bool
    let lastSynced: Date?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("About you")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(NHSTheme.textPrimary)

                    Text("Date of birth and sex come from Apple Health when available. Tap missing fields to add them, or smoking to update your habit.")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(NHSTheme.primaryBlue)
                }
            }

            HStack(spacing: 10) {
                Label(healthKitAvailable ? "Apple Health connected" : "Apple Health unavailable",
                      systemImage: healthKitAvailable ? "heart.text.square.fill" : "heart.slash")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(healthKitAvailable ? NHSTheme.primaryBlue : NHSTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(NHSTheme.lightBlue)
                    .clipShape(Capsule())

                if let lastSynced {
                    Text("Synced \(lastSynced.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }

            HStack(spacing: 12) {
                quickStat(title: "Age", value: "\(profile.age)")
            }
        }
        .nhsCard()
    }

    private func quickStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(NHSTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(NHSTheme.lightBlue)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
