import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("yoloModeDefault") private var yoloModeDefault: Bool = false
    @Query var projects: [Project]
    @State private var selectedProvider: ProviderItem?

    private var totalCost: Double {
        projects.compactMap { $0.pipeline?.totalCostUSD }.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                ProviderListView(selection: $selectedProvider)
                    .frame(minWidth: 200, maxWidth: 260)

                Group {
                    if let provider = selectedProvider {
                        ProviderDetailView(item: provider)
                    } else {
                        ContentUnavailableView(
                            "Select a Provider",
                            systemImage: "cpu",
                            description: Text("Choose a provider from the list to configure its settings.")
                        )
                    }
                }
                .frame(minWidth: 400)
            }

            Divider()

            Form {
                Section("Defaults") {
                    Toggle("Yolo Mode by default", isOn: $yoloModeDefault)
                    Text("Skips human approval gates — stages run automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Usage") {
                    LabeledContent("Total Projects", value: "\(projects.count)")
                    LabeledContent("Total Cost", value: String(format: "$%.4f", totalCost))
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
        }
        .navigationTitle("Settings")
    }
}
