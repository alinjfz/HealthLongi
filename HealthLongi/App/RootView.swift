import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedTab: AppTab = .dashboard
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView(onComplete: { showOnboarding = false })
            } else {
                mainTabs
            }
        }
        .background(NHSTheme.background)
        .onAppear { migrateLegacyProfilesIfNeeded() }
    }

    private func migrateLegacyProfilesIfNeeded() {
        for profile in profiles {
            profile.migrateLegacyQuestionnaireCompletionIfNeeded()
        }
        try? modelContext.save()
    }

    private var needsOnboarding: Bool {
        profiles.first?.onboardingComplete != true
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "heart.text.square.fill")
                }
                .tag(AppTab.dashboard)

            AssessHubView()
                .tabItem {
                    Label("Assess", systemImage: "list.clipboard.fill")
                }
                .tag(AppTab.assess)

            ProfileSummaryView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(NHSTheme.primaryBlue)
    }
}

#Preview {
    RootView()
        .environment(\.appDependencies, .preview())
        .modelContainer(for: [UserProfile.self, RiskAssessment.self], inMemory: true)
}
