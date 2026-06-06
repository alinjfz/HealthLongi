import SwiftUI

struct CompletenessChecklistSheet: View {
    let missingItems: [CompletenessItemID]
    var onSelect: (CompletenessItemID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if missingItems.isEmpty {
                    Section {
                        Label("All core items complete", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Section("Still needed") {
                        ForEach(missingItems) { item in
                            Button {
                                dismiss()
                                onSelect(item)
                            } label: {
                                Label(item.title, systemImage: item.icon)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Completeness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
