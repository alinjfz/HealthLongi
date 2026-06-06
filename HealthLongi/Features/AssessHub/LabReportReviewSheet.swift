import SwiftUI

struct LabReportReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let parsedValues: [LabReportOCRService.ParsedValue]
    var onConfirm: ([LabReportOCRService.ParsedValue]) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Review values found in your report. Confirm to fill the form — you can edit before saving.")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section("Detected biomarkers") {
                    ForEach(parsedValues) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.marker.label)
                                    .font(.subheadline.weight(.medium))
                                Text(item.marker.unit)
                                    .font(.caption)
                                    .foregroundStyle(NHSTheme.textSecondary)
                            }
                            Spacer()
                            Text(formattedValue(item))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NHSTheme.primaryBlue)
                        }
                    }
                }
            }
            .navigationTitle("Import Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use These Values") {
                        onConfirm(parsedValues)
                        dismiss()
                    }
                }
            }
        }
    }

    private func formattedValue(_ item: LabReportOCRService.ParsedValue) -> String {
        if item.marker.isIntegerField {
            return "\(Int(item.value))"
        }
        return String(format: "%.2f", item.value)
    }
}
