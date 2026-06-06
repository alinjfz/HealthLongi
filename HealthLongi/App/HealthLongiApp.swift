//
//  HealthLongiApp.swift
//  HealthLongi
//

import SwiftData
import SwiftUI

@main
struct HealthLongiApp: App {
    private let dependencies = AppDependencies.live()

    private let sharedModelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appDependencies, dependencies)
        }
        .modelContainer(sharedModelContainer)
    }
}
