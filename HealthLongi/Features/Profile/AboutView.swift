import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("App") {
                LabeledContent("Name", value: AppInfo.appName)
                LabeledContent("Version", value: AppInfo.version)
                LabeledContent("Build", value: AppInfo.buildNumber)
                LabeledContent("Developer", value: AppInfo.developerName)
            }

            Section("Information") {
                Link("Privacy Policy", destination: AppInfo.privacyPolicyURL)
                Link("Terms of Service", destination: AppInfo.termsOfServiceURL)
                Link("Website", destination: AppInfo.websiteURL)
            }

            Section("Support") {
                Link("Contact Support", destination: URL(string: "mailto:\(AppInfo.supportEmail)")!)
            }

            Section("Disclaimer") {
                Text(AppInfo.disclaimer)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .navigationTitle("About Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
