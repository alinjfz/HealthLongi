//
//  HealthLongiApp.swift
//  HealthLongi
//

import SwiftData
import SwiftUI

@main
struct HealthLongiApp: App {
    private let dependencies = AppDependencies.live()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([UserProfile.self, RiskAssessment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appDependencies, dependencies)
        }
        .modelContainer(sharedModelContainer)
    }
}
