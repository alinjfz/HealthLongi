import SwiftUI

struct TrendsView: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel: TrendsViewModel?

    private var chartMetrics: [HealthKitMetric] {
        HealthKitMetric.allCases.filter(\.supportsTrendChart)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let viewModel {
                        Picker("Range", selection: Binding(
                            get: { viewModel.selectedRange },
                            set: { newValue in
                                viewModel.selectedRange = newValue
                                Task { await viewModel.load() }
                            }
                        )) {
                            ForEach(TrendRange.allCases) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(chartMetrics) { metric in
                                    Button {
                                        viewModel.selectedMetric = metric
                                        Task { await viewModel.load() }
                                    } label: {
                                        MetricTrendCard(metric: metric, isSelected: viewModel.selectedMetric == metric)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if viewModel.isLoading {
                            ProgressView("Loading trends…")
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(NHSTheme.textSecondary)
                        } else {
                            HealthMetricChart(metric: viewModel.selectedMetric, dataPoints: viewModel.dataPoints)
                        }

                        Text("Trends are built from Apple Health on your device. Raw values are never sent to AI.")
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Trends")
            .task {
                if viewModel == nil {
                    viewModel = TrendsViewModel(healthDataProvider: dependencies.healthDataProvider)
                }
                await viewModel?.load()
            }
        }
    }
}

#Preview {
    TrendsView()
        .environment(\.appDependencies, .preview())
}
