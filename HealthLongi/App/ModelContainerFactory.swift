import Foundation
import SwiftData

enum ModelContainerFactory {
    static func make() -> ModelContainer {
        let schema = Schema([UserProfile.self, RiskAssessment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Lightweight migration can fail when an existing store predates new required fields.
            // Remove the incompatible store once and recreate a fresh container.
            removePersistentStore(at: config.url)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after store reset: \(error)")
            }
        }
    }

    private static func removePersistentStore(at url: URL) {
        let fileManager = FileManager.default
        let related = [url, URL(fileURLWithPath: url.path + "-shm"), URL(fileURLWithPath: url.path + "-wal")]
        for fileURL in related where fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
