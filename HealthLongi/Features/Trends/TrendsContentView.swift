import SwiftUI
import SwiftData

struct TrendsContentView: View {
    @Environment(\.appDependencies) private var dependencies
    @Query private var profiles: [UserProfile]

    @State private var viewModel: TrendsViewModel?
    @State private var showSettings = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let viewModel {
                header(viewModel: viewModel)

                if viewModel.isLoading {
                    ProgressView("Loading trends…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)
                } else {
                    UnifiedTrendChart(
                        series: viewModel.series,
                        usesNormalizedAxis: viewModel.usesNormalizedAxis,
                        singleMetric: viewModel.singleMetric
                    )
                }

                Text("Trends are built from Apple Health and your saved lab data on this device. Raw values are never sent to AI.")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
        .task {
            if viewModel == nil {
                viewModel = TrendsViewModel(healthDataProvider: dependencies.healthDataProvider)
            }
            profile?.migrateLabResultsHistoryIfNeeded()
            await reload()
        }
        .onChange(of: profiles.first?.labResultsHistory.count) {
            Task { await reload() }
        }
        .sheet(isPresented: $showSettings) {
            if let viewModel, let profile {
                TrendMetricSettingsSheet(viewModel: viewModel, profileSex: profile.sex)
                    .onDisappear {
                        Task { await reload() }
                    }
            }
        }
    }

    @ViewBuilder
    private func header(viewModel: TrendsViewModel) -> some View {
        HStack(alignment: .center) {
            Text("Health Trends")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(NHSTheme.primaryBlue)
                    .frame(width: 32, height: 32)
                    .background(NHSTheme.lightBlue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Measurement settings")
        }

        Picker("Range", selection: Binding(
            get: { viewModel.selectedRange },
            set: { newValue in
                viewModel.selectedRange = newValue
                Task { await reload() }
            }
        )) {
            ForEach(TrendRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private func reload() async {
        guard let viewModel else { return }
        await viewModel.load(labHistory: profile?.labResultsHistory ?? [])
    }
}
