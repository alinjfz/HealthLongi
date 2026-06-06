import SwiftUI

enum HealthDomain: String, Identifiable {
    case cardiovascular
    case mental
    case metabolic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cardiovascular: "Cardiovascular"
        case .mental: "Mental Health"
        case .metabolic: "Metabolic"
        }
    }

    var subtitle: String {
        switch self {
        case .cardiovascular: "Heart & circulation risk"
        case .mental: "Mood & anxiety indicators"
        case .metabolic: "Diabetes & weight risk"
        }
    }

    var icon: String {
        switch self {
        case .cardiovascular: "heart.fill"
        case .mental: "brain.head.profile"
        case .metabolic: "figure.walk"
        }
    }
}

struct DomainDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let domain: HealthDomain
    let profile: AbstractedRiskProfile

    @State private var showDataSourceInfo = false

    private var indicatorColor: Color {
        switch domain {
        case .cardiovascular: NHSTheme.riskColor(for: profile.cardioRisk)
        case .mental: NHSTheme.mentalColor(for: profile.mentalHealth)
        case .metabolic: NHSTheme.riskColor(for: profile.metabolic)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    domainHeaderCard

                    switch domain {
                    case .cardiovascular:
                        CardioDetailContent(riskLevel: profile.cardioRisk)
                    case .mental:
                        MentalDetailContent(mentalFlag: profile.mentalHealth)
                    case .metabolic:
                        MetabolicDetailContent(riskLevel: profile.metabolic)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle(domain.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showDataSourceInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(NHSTheme.primaryBlue)
                    }
                }
            }
            .sheet(isPresented: $showDataSourceInfo) {
                DataSourceInfoSheet(domain: domain)
            }
        }
    }

    private var domainHeaderCard: some View {
        DomainStatusCard(
            title: domain.title,
            subtitle: domain.subtitle,
            color: indicatorColor,
            icon: domain.icon
        )
    }
}
