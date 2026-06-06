import SwiftUI
import SwiftData

struct ProfileDeveloperMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAbout = false
    @State private var showGDPRDelete = false
    @State private var loadingScenarioID: String?
    @State private var seedResult: DemoSeeder.SeedResult?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                developerTile(
                    title: "About Us",
                    subtitle: "App info, privacy policy, and support",
                    icon: "info.circle.fill",
                    tint: NHSTheme.primaryBlue
                ) {
                    showAbout = true
                }

                developerTile(
                    title: "Delete My Data",
                    subtitle: "Remove all data stored on this device",
                    icon: "trash.fill",
                    tint: .red
                ) {
                    showGDPRDelete = true
                }

                #if DEBUG
                demoScenariosSection
                #endif
            }
            .padding()
        }
        .background(NHSTheme.background)
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showGDPRDelete) {
            GDPRDeleteView()
        }
        .alert(
            seedResult?.scenarioTitle ?? "Demo data loaded",
            isPresented: Binding(
                get: { seedResult != nil },
                set: { if !$0 { seedResult = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = seedResult?.healthKitMessage {
                Text(message)
            }
        }
    }

    #if DEBUG
    private var demoScenariosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Demo Scenarios", systemImage: "wand.and.stars")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Loads profile, questionnaire scores, and all HealthKit metrics used by the app into Apple Health.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(DemoHealthScenario.all) { scenario in
                Button {
                    Task { await loadScenario(scenario) }
                } label: {
                    scenarioTile(scenario, isLoading: loadingScenarioID == scenario.id)
                }
                .buttonStyle(.plain)
                .disabled(loadingScenarioID != nil)
            }
        }
        .padding()
        .background(NHSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func scenarioTile(_ scenario: DemoHealthScenario, isLoading: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NHSTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(scenario.subtitle)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }
        }
        .padding(12)
        .background(NHSTheme.lightBlue.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadScenario(_ scenario: DemoHealthScenario) async {
        loadingScenarioID = scenario.id
        seedResult = await DemoSeeder.seed(scenario: scenario, context: modelContext)
        loadingScenarioID = nil
    }
    #endif

    private func developerTile(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tint.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                        .multilineTextAlignment(.leading)
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
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileDeveloperMenuView()
    }
}
