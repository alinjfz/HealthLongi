import Foundation

struct LabImportRecord: Codable, Identifiable, Sendable, Equatable {
    var id: UUID
    var importedAt: Date
    var sourceFilename: String?
    var biomarkerCount: Int
    var biomarkerLabels: [String]
    var reportDate: Date?

    init(
        id: UUID = UUID(),
        importedAt: Date = .now,
        sourceFilename: String? = nil,
        biomarkerCount: Int,
        biomarkerLabels: [String],
        reportDate: Date? = nil
    ) {
        self.id = id
        self.importedAt = importedAt
        self.sourceFilename = sourceFilename
        self.biomarkerCount = biomarkerCount
        self.biomarkerLabels = biomarkerLabels
        self.reportDate = reportDate
    }
}
