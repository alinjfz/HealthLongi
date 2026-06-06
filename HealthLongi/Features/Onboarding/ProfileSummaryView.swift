import SwiftUI
import SwiftData

struct ProfileSummaryView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = ProfileHealthViewModel()
    @State private var showEditDemographics = false
    @State private var selectedMetric: ProfileHealthMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = profiles.first {
                        ProfileHeaderCard(
                            profile: profile,
                            healthKitAvailable: viewModel.healthKitAvailable,
                            lastSynced: viewModel.lastSynced,
                            isLoading: viewModel.isLoading
                        )

                        assessmentsCard(profile)

                        NavigationLink {
                            AppointmentPrepView(profile: profile)
                        } label: {
                            gpPrepCard
                        }
                        .buttonStyle(.plain)

                        ForEach(viewModel.groups) { group in
                            ProfileHealthSectionCard(group: group) { metric in
                                handleMetricTap(metric)
                            }
                        }

                        NavigationLink {
                            ProfileDeveloperMenuView()
                        } label: {
                            developerEntryTile
                        }
                        .buttonStyle(.plain)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .nhsCard()
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Profile")
            .refreshable {
                await refreshProfile()
            }
            .task {
                await refreshProfile()
            }
            .sheet(isPresented: $showEditDemographics) {
                if let profile = profiles.first {
                    EditDemographicsView(profile: profile)
                        .onDisappear { Task { await refreshProfile() } }
                }
            }
            .sheet(item: $selectedMetric) { metric in
                if let profile = profiles.first {
                    EditProfileMetricSheet(metric: metric, profile: profile) {
                        Task { await refreshProfile() }
                    }
                }
            }
        }
    }

    private var gpPrepCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(NHSTheme.lightBlue)
                    .frame(width: 48, height: 48)
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(NHSTheme.primaryBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Prepare for GP Visit")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.textPrimary)
                Text("Select concerns and export a PDF brief")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .padding()
        .background(NHSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var developerEntryTile: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(NHSTheme.lightBlue)
                    .frame(width: 48, height: 48)
                Image(systemName: "hammer.fill")
                    .font(.title3)
                    .foregroundStyle(NHSTheme.primaryBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Developer")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.textPrimary)
                Text("About, delete data, and demo tools")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .padding()
        .background(NHSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func assessmentsCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Assessments")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(QuestionnaireKind.allCases) { kind in
                if profile.isComplete(kind), let date = profile.completedAt(kind) {
                    LabeledContent(kind.title, value: date.formatted(date: .abbreviated, time: .omitted))
                }
            }

            if !QuestionnaireKind.allCases.contains(where: { profile.isComplete($0) }) {
                Text("No check-ins completed yet.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
    }

    private func refreshProfile() async {
        guard let profile = profiles.first else { return }
        await viewModel.refresh(profile: profile, provider: dependencies.healthDataProvider)
        try? modelContext.save()
    }

    private func handleMetricTap(_ metric: ProfileHealthMetric) {
        guard metric.key == .smoking else {
            guard metric.allowsManualEntry else { return }
            selectedMetric = metric
            return
        }
        showEditDemographics = true
    }
}

#Preview {
    ProfileSummaryView()
        .environment(\.appDependencies, .preview())
        .modelContainer(for: [UserProfile.self, RiskAssessment.self], inMemory: true)
}
