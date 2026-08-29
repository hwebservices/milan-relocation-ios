import SwiftUI

struct HousingTargetsEditorView: View {
    @Environment(HousingStore.self) private var housingStore
    @Environment(\.dismiss) private var dismiss

    @State private var maximumMonthlyCost: String
    @State private var maximumMoveInCash: String
    @State private var minimumBedrooms: Int
    @State private var minimumSquareMeters: Int
    @State private var requiresElevator: Bool
    @State private var furnishedPreference: FurnishedStatus?

    init(targets: MilanHousingTargets) {
        _maximumMonthlyCost = State(initialValue: NSDecimalNumber(decimal: targets.maximumMonthlyCost).stringValue)
        _maximumMoveInCash = State(initialValue: NSDecimalNumber(decimal: targets.maximumMoveInCash).stringValue)
        _minimumBedrooms = State(initialValue: targets.minimumBedrooms)
        _minimumSquareMeters = State(initialValue: targets.minimumSquareMeters)
        _requiresElevator = State(initialValue: targets.requiresElevator)
        _furnishedPreference = State(initialValue: targets.furnishedPreference)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    currencyField("Maximum monthly", text: $maximumMonthlyCost, id: "housing-target-monthly")
                    currencyField("Maximum move-in cash", text: $maximumMoveInCash, id: "housing-target-move-in")
                }
                Section("Requirements") {
                    Stepper("Minimum bedrooms: \(minimumBedrooms)", value: $minimumBedrooms, in: 0 ... 10)
                    Stepper("Minimum size: \(minimumSquareMeters) m²", value: $minimumSquareMeters, in: 10 ... 500, step: 5)
                    Toggle("Elevator required", isOn: $requiresElevator)
                    Picker("Furnishing", selection: $furnishedPreference) {
                        Text("Any").tag(nil as FurnishedStatus?)
                        ForEach(FurnishedStatus.allCases) { Text($0.rawValue).tag($0 as FurnishedStatus?) }
                    }
                }
            }
            .navigationTitle("Milan Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("housing-targets-save")
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func currencyField(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .accessibilityIdentifier(id)
        }
    }

    private func save() {
        housingStore.updateTargets(
            MilanHousingTargets(
                maximumMonthlyCost: decimal(maximumMonthlyCost), maximumMoveInCash: decimal(maximumMoveInCash),
                minimumBedrooms: minimumBedrooms, minimumSquareMeters: minimumSquareMeters,
                requiresElevator: requiresElevator, furnishedPreference: furnishedPreference
            )
        )
        dismiss()
    }

    private func decimal(_ text: String) -> Decimal {
        max(Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) ?? 0, 0)
    }
}

struct HousingFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    let neighborhoods: [String]
    @Binding var sort: HousingSort
    @Binding var price: HousingPriceFilter
    @Binding var neighborhood: String?
    @Binding var qualification: HousingQualification?
    @Binding var followUp: HousingFollowUpFilter

    var body: some View {
        NavigationStack {
            Form {
                Picker("Sort", selection: $sort) {
                    ForEach(HousingSort.allCases) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("housing-filter-sort")
                Picker("Price", selection: $price) {
                    ForEach(HousingPriceFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("housing-filter-price")
                Picker("Neighborhood", selection: $neighborhood) {
                    Text("All neighborhoods").tag(nil as String?)
                    ForEach(neighborhoods, id: \.self) { Text($0).tag($0 as String?) }
                }
                .accessibilityIdentifier("housing-filter-neighborhood")
                Picker("Status", selection: $qualification) {
                    Text("All statuses").tag(nil as HousingQualification?)
                    ForEach(HousingQualification.allCases) { Text($0.rawValue).tag($0 as HousingQualification?) }
                }
                .accessibilityIdentifier("housing-filter-status")
                Picker("Follow-up", selection: $followUp) {
                    ForEach(HousingFollowUpFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("housing-filter-follow-up")
                Button("Clear filters") {
                    sort = .priceLowToHigh
                    price = .all
                    neighborhood = nil
                    qualification = nil
                    followUp = .all
                }
                .accessibilityIdentifier("housing-clear-filters")
            }
            .navigationTitle("Sort & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("housing-apply-filters")
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
