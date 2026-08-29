import SwiftUI

struct ApartmentEditorView: View {
    @Environment(HousingStore.self) private var housingStore
    @Environment(\.dismiss) private var dismiss

    private let originalListing: ApartmentListing?

    @State private var address: String
    @State private var neighborhood: String
    @State private var listingURL: String
    @State private var rent: String
    @State private var condominio: String
    @State private var utilities: String
    @State private var bedrooms: Int
    @State private var squareMeters: Int
    @State private var hasElevator: Bool
    @State private var furnishedStatus: FurnishedStatus
    @State private var contractType: HousingContractType
    @State private var availabilityDate: Date
    @State private var deposit: String
    @State private var agencyFee: String
    @State private var otherCosts: String
    @State private var qualification: HousingQualification
    @State private var contactAttempts: [HousingContactAttempt]
    @State private var contactMethod: HousingContactMethod = .email
    @State private var contactResponse = ""
    @State private var hasFollowUp: Bool
    @State private var nextFollowUpDate: Date
    @State private var notes: String
    @State private var showsDeleteConfirmation = false

    init(listing: ApartmentListing?) {
        originalListing = listing
        _address = State(initialValue: listing?.address ?? "")
        _neighborhood = State(initialValue: listing?.neighborhood ?? "")
        _listingURL = State(initialValue: listing?.listingURL ?? "")
        _rent = State(initialValue: listing.map { Self.decimalText($0.rent) } ?? "")
        _condominio = State(initialValue: listing.map { Self.decimalText($0.condominio) } ?? "")
        _utilities = State(initialValue: listing.map { Self.decimalText($0.utilitiesEstimate) } ?? "")
        _bedrooms = State(initialValue: listing?.bedrooms ?? 2)
        _squareMeters = State(initialValue: listing?.squareMeters ?? 70)
        _hasElevator = State(initialValue: listing?.hasElevator ?? true)
        _furnishedStatus = State(initialValue: listing?.furnishedStatus ?? .furnished)
        _contractType = State(initialValue: listing?.contractType ?? .fourPlusFour)
        _availabilityDate = State(initialValue: listing?.availabilityDate ?? .now)
        _deposit = State(initialValue: listing.map { Self.decimalText($0.deposit) } ?? "")
        _agencyFee = State(initialValue: listing.map { Self.decimalText($0.agencyFee) } ?? "")
        _otherCosts = State(initialValue: listing.map { Self.decimalText($0.otherMoveInCosts) } ?? "")
        _qualification = State(initialValue: listing?.qualification ?? .needsReview)
        _contactAttempts = State(initialValue: listing?.contactAttempts ?? [])
        _hasFollowUp = State(initialValue: listing?.nextFollowUpDate != nil)
        _nextFollowUpDate = State(initialValue: listing?.nextFollowUpDate ?? .now)
        _notes = State(initialValue: listing?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Listing") {
                    TextField("Address", text: $address).accessibilityIdentifier("housing-address")
                    TextField("Neighborhood", text: $neighborhood).accessibilityIdentifier("housing-neighborhood")
                    currencyField("Rent", text: $rent, id: "housing-rent")
                    TextField("Listing URL", text: $listingURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("housing-listing-url")
                    if let url = validatedListingURL {
                        Link(destination: url) { Label("Open listing", systemImage: "safari") }
                            .accessibilityIdentifier("housing-open-listing")
                    }
                    DatePicker("Available", selection: $availabilityDate, displayedComponents: .date)
                        .accessibilityIdentifier("housing-availability")
                }

                Section("Monthly cost") {
                    currencyField("Condominio", text: $condominio, id: "housing-condominio")
                    currencyField("Utilities estimate", text: $utilities, id: "housing-utilities")
                    LabeledContent("Total", value: euro(totalMonthlyCost))
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("housing-monthly-total")
                }

                Section("Home") {
                    Stepper("Bedrooms: \(bedrooms)", value: $bedrooms, in: 0 ... 10)
                        .accessibilityIdentifier("housing-bedrooms")
                    Stepper("Square meters: \(squareMeters)", value: $squareMeters, in: 10 ... 500, step: 5)
                        .accessibilityIdentifier("housing-square-meters")
                    Toggle("Elevator", isOn: $hasElevator).accessibilityIdentifier("housing-elevator")
                    Picker("Furnished", selection: $furnishedStatus) {
                        ForEach(FurnishedStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("housing-furnished")
                    Picker("Contract", selection: $contractType) {
                        ForEach(HousingContractType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("housing-contract")
                }

                Section("Move-in cash") {
                    currencyField("Deposit", text: $deposit, id: "housing-deposit")
                    currencyField("Agency fee", text: $agencyFee, id: "housing-agency-fee")
                    LabeledContent("First month", value: euro(totalMonthlyCost))
                    currencyField("Other costs", text: $otherCosts, id: "housing-other-costs")
                    LabeledContent("Required cash", value: euro(requiredMoveInCash))
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("housing-move-in-total")
                }

                Section("Decision") {
                    Picker("Qualification", selection: $qualification) {
                        ForEach(HousingQualification.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("housing-qualification")
                    targetComparison
                }

                Section("Contact and follow-up") {
                    ForEach(contactAttempts) { attempt in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(attempt.method.rawValue) · \(attempt.date.relocationShort)")
                                .font(.subheadline.weight(.semibold))
                            Text(attempt.response ?? "No response recorded")
                                .font(.caption)
                                .foregroundStyle(MRColor.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Picker("Contact method", selection: $contactMethod) {
                        ForEach(HousingContactMethod.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("housing-contact-method")
                    TextField("Response (optional)", text: $contactResponse, axis: .vertical)
                        .accessibilityIdentifier("housing-contact-response")
                    Button("Record contact attempt", systemImage: "paperplane") { addContactAttempt() }
                        .accessibilityIdentifier("housing-add-contact")
                    Toggle("Schedule follow-up", isOn: $hasFollowUp)
                        .accessibilityIdentifier("housing-has-follow-up")
                    if hasFollowUp {
                        DatePicker("Next follow-up", selection: $nextFollowUpDate, displayedComponents: .date)
                            .accessibilityIdentifier("housing-follow-up-date")
                    }
                }

                if let history = originalListing?.priceHistory, !history.isEmpty {
                    Section("Price history") {
                        ForEach(history.sorted { $0.date > $1.date }) { change in
                            LabeledContent(change.date.relocationShort) {
                                Text("\(euro(change.previousRent)) → \(euro(change.newRent))")
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80).accessibilityIdentifier("housing-notes")
                }

                if originalListing != nil {
                    Section {
                        Button("Delete Listing", role: .destructive) { showsDeleteConfirmation = true }
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("housing-delete-listing")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MRColor.background)
            .navigationTitle(originalListing == nil ? "New Listing" : "Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.accessibilityIdentifier("housing-editor-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .accessibilityIdentifier("housing-save-listing")
                }
            }
            .alert("Delete this listing?", isPresented: $showsDeleteConfirmation) {
                Button("Delete", role: .destructive) { deleteListing() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes “\(address)” and its local contact and price history. This cannot be undone.")
            }
        }
        .preferredColorScheme(.light)
    }

    private var targetComparison: some View {
        let listing = draftListing
        let withinBudget = listing.isWithinBudget(targets: housingStore.targets)
        let requirements = listing.meetsRequirements(targets: housingStore.targets)
        return VStack(alignment: .leading, spacing: 6) {
            Label(withinBudget ? "Within housing budget" : "Outside housing budget", systemImage: withinBudget ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(withinBudget ? MRColor.success : MRColor.red)
            Label(requirements ? "Meets space and amenity targets" : "One or more requirements need review", systemImage: requirements ? "checkmark.circle.fill" : "magnifyingglass.circle")
                .foregroundStyle(requirements ? MRColor.success : MRColor.amber)
        }
        .font(.caption.weight(.semibold))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("housing-target-comparison")
    }

    private func currencyField(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .accessibilityLabel("\(title) in euros")
                .accessibilityIdentifier(id)
        }
    }

    private var canSave: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !neighborhood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && decimal(rent) > 0
    }

    private var totalMonthlyCost: Decimal { decimal(rent) + decimal(condominio) + decimal(utilities) }
    private var requiredMoveInCash: Decimal { decimal(deposit) + decimal(agencyFee) + totalMonthlyCost + decimal(otherCosts) }
    private var validatedListingURL: URL? {
        let value = listingURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host != nil else { return nil }
        return url
    }

    private var draftListing: ApartmentListing {
        ApartmentListing(
            id: originalListing?.id ?? UUID(), address: address, neighborhood: neighborhood,
            listingURL: listingURL, rent: decimal(rent), condominio: decimal(condominio),
            utilitiesEstimate: decimal(utilities), bedrooms: bedrooms, squareMeters: squareMeters,
            hasElevator: hasElevator, furnishedStatus: furnishedStatus, contractType: contractType,
            availabilityDate: availabilityDate, deposit: decimal(deposit), agencyFee: decimal(agencyFee),
            otherMoveInCosts: decimal(otherCosts), qualification: qualification,
            contactAttempts: contactAttempts, nextFollowUpDate: hasFollowUp ? nextFollowUpDate : nil,
            priceHistory: originalListing?.priceHistory ?? [], notes: cleanedNotes
        )
    }

    private var cleanedNotes: String? {
        let value = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func addContactAttempt() {
        let response = contactResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        contactAttempts.append(
            HousingContactAttempt(date: .now, method: contactMethod, response: response.isEmpty ? nil : response, responseDate: response.isEmpty ? nil : .now)
        )
        contactResponse = ""
    }

    private func save() {
        if originalListing == nil { housingStore.create(draftListing) }
        else { housingStore.update(draftListing) }
        dismiss()
    }

    private func deleteListing() {
        guard let originalListing else { return }
        housingStore.delete(id: originalListing.id)
        dismiss()
    }

    private func decimal(_ text: String) -> Decimal {
        max(Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) ?? 0, 0)
    }

    private static func decimalText(_ value: Decimal) -> String { NSDecimalNumber(decimal: value).stringValue }
    private func euro(_ value: Decimal) -> String { value.formatted(.currency(code: "EUR").precision(.fractionLength(0 ... 2))) }
}
