import Foundation

@MainActor
@Observable
final class ProfileHealthViewModel {
    var groups: [ProfileHealthGroup] = []
    var isLoading = false
    var lastSynced: Date?
    var healthKitAvailable = false
    var errorMessage: String?

    func refresh(profile: UserProfile, provider: any HealthDataProviding) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        healthKitAvailable = provider.isHealthDataAvailable
        var demographics = ProfileDemographicsSnapshot()

        if healthKitAvailable {
            do {
                try await provider.requestAuthorization()
                demographics = await provider.fetchProfileDemographics()
                lastSynced = .now

                if let dob = demographics.dateOfBirth {
                    profile.dateOfBirth = dob
                }
                if let sex = demographics.biologicalSex {
                    profile.sex = sex
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        groups = Self.buildGroups(profile: profile, demographics: demographics)
    }

    func clearManualValue(for key: ProfileHealthMetricKey, profile: UserProfile) {
        guard key == .dateOfBirth || key == .sex else { return }

        var manual = profile.manualHealthData ?? .empty
        switch key {
        case .dateOfBirth: manual.dateOfBirth = nil
        case .sex: manual.sexRaw = nil
        default: break
        }
        manual.lastUpdated = .now
        profile.manualHealthData = manual.nilIfEmpty
    }

    func saveManualValue(_ value: String, for key: ProfileHealthMetricKey, profile: UserProfile) {
        var manual = profile.manualHealthData ?? .empty

        switch key {
        case .dateOfBirth:
            if let date = ISO8601DateFormatter.profileDate.date(from: value) {
                manual.dateOfBirth = date
                profile.dateOfBirth = date
            }
        case .sex:
            if let sex = Sex(rawValue: value) {
                manual.sexRaw = sex.rawValue
                profile.sex = sex
            }
        default:
            break
        }

        manual.lastUpdated = .now
        profile.manualHealthData = manual.nilIfEmpty
    }

    private static func buildGroups(
        profile: UserProfile,
        demographics: ProfileDemographicsSnapshot
    ) -> [ProfileHealthGroup] {
        let manual = profile.manualHealthData
        let dob = resolveDateOfBirth(profile: profile, demographics: demographics, manual: manual)
        let sex = resolveSex(profile: profile, demographics: demographics, manual: manual)

        return [
            ProfileHealthGroup(title: "About You", icon: "person.crop.circle.fill", metrics: [
                metric(.dateOfBirth, title: "Date of birth", value: dob.value, icon: "calendar", source: dob.source),
                metric(.sex, title: "Sex at birth", value: sex.value, icon: "person.fill", source: sex.source),
                metric(
                    .smoking,
                    title: "Smoking",
                    value: profile.smokingStatus.displayName,
                    icon: "smoke.fill",
                    source: .manual,
                    allowsManualEntry: true
                )
            ])
        ]
    }

    private static func metric(
        _ key: ProfileHealthMetricKey,
        title: String,
        value: String,
        icon: String,
        source: HealthMetricSource,
        allowsManualEntry: Bool = true
    ) -> ProfileHealthMetric {
        ProfileHealthMetric(
            key: key,
            title: title,
            value: value,
            detail: nil,
            icon: icon,
            source: source,
            allowsManualEntry: allowsManualEntry && source != .healthKit
        )
    }

    private static func resolveDateOfBirth(
        profile: UserProfile,
        demographics: ProfileDemographicsSnapshot,
        manual: ManualHealthData?
    ) -> (value: String, source: HealthMetricSource) {
        if let dob = demographics.dateOfBirth {
            return (formattedDateOfBirth(dob), .healthKit)
        }
        if let dob = manual?.dateOfBirth {
            return (formattedDateOfBirth(dob), .manual)
        }
        if profile.onboardingComplete {
            return (formattedDateOfBirth(profile.dateOfBirth), .manual)
        }
        return ("—", .unavailable)
    }

    private static func formattedDateOfBirth(_ date: Date) -> String {
        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        let years = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 0
        return "\(formatted) (\(years))"
    }

    private static func resolveSex(
        profile: UserProfile,
        demographics: ProfileDemographicsSnapshot,
        manual: ManualHealthData?
    ) -> (value: String, source: HealthMetricSource) {
        if let sex = demographics.biologicalSex {
            return (sex.displayName, .healthKit)
        }
        if let raw = manual?.sexRaw, let sex = Sex(rawValue: raw) {
            return (sex.displayName, .manual)
        }
        if profile.onboardingComplete {
            return (profile.sex.displayName, .manual)
        }
        return ("—", .unavailable)
    }
}

private extension ManualHealthData {
    var nilIfEmpty: ManualHealthData? {
        let hasValue = dateOfBirth != nil || sexRaw != nil
        return hasValue ? self : nil
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

extension ISO8601DateFormatter {
    static let profileDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
