import SwiftUI
import SwiftData

struct ProfileDeveloperMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAbout = false
    @State private var showGDPRDelete = false
    @State private var showDemoLoaded = false

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
                developerTile(
                    title: "Load Demo Data",
                    subtitle: "Seed a sample profile for testing",
                    icon: "wand.and.stars",
                    tint: .purple
                ) {
                    DemoSeeder.seedDemoProfile(context: modelContext)
                    showDemoLoaded = true
                }
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
        .alert("Demo data loaded", isPresented: $showDemoLoaded) {
            Button("OK", role: .cancel) {}
        }
    }

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
