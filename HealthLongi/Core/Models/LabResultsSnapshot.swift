import Foundation

struct LabResultsSnapshot: Codable, Identifiable, Sendable, Equatable {
    var id: UUID
    var recordedAt: Date
    var results: LabResults

    init(id: UUID = UUID(), recordedAt: Date, results: LabResults) {
        self.id = id
        self.recordedAt = recordedAt
        self.results = results
    }
}
