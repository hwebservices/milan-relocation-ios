import SwiftUI

struct HousingView: View {
    @Environment(HousingStore.self) private var housingStore

    @State private var selectedListing: ApartmentListing?
    @State private var showsNewListing = false
    @State private var showsTargets = false
    @State private var showsFilters = false
    @State private var sort: HousingSort = .priceLowToHigh
    @State private var price: HousingPriceFilter = .all
    @State private var neighborhood: String?
    @State private var qualification: HousingQualification?
    @State private var followUp: HousingFollowUpFilter = .all

    private var filteredListings: [ApartmentListing] {
        housingStore.filteredListings(
            sort: sort, price: price, neighborhood: neighborhood, qualification: qualification, followUp: followUp
        )
    }

    private var neighborhoods: [String] {
        Array(Set(housingStore.listings.map(\.neighborhood))).sorted()
    }

    private var overdueCount: Int { housingStore.listings.filter { $0.isFollowUpOverdue() }.count }
    private var withinBudgetCount: Int { housingStore.listings.filter { $0.isWithinBudget(targets: housingStore.targets) }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(
                    eyebrow: "Home search",
                    title: "Housing pipeline",
                    detail: "Compare true monthly cost, move-in cash, requirements, and every landlord follow-up."
                )
                summary
                targetSummary
                pipeline
            }
            .relocationPage()
        }
        .background(MRColor.background)
        .navigationTitle("Housing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showsFilters = true } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Sort and filter housing")
                .accessibilityIdentifier("housing-filter-button")
                Button { showsNewListing = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add apartment listing")
                    .accessibilityIdentifier("housing-add-listing")
            }
        }
        .sheet(isPresented: $showsNewListing) { ApartmentEditorView(listing: nil) }
        .sheet(item: $selectedListing) { ApartmentEditorView(listing: $0) }
        .sheet(isPresented: $showsTargets) { HousingTargetsEditorView(targets: housingStore.targets) }
        .sheet(isPresented: $showsFilters) {
            HousingFiltersView(
                neighborhoods: neighborhoods, sort: $sort, price: $price, neighborhood: $neighborhood,
                qualification: $qualification, followUp: $followUp
            )
        }
    }

    private var summary: some View {
        MetricGrid(columns: 3) {
            MetricBlock(label: "Pipeline", value: "\(housingStore.listings.count)", detail: "listings")
            MetricBlock(label: "Within budget", value: "\(withinBudgetCount)", detail: "qualified by cost", emphasized: true)
            MetricBlock(label: "Follow-ups", value: "\(overdueCount)", detail: "overdue")
        }
        .accessibilityIdentifier("housing-summary")
    }

    private var targetSummary: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            SectionLabel(title: "Milan targets", action: "Edit")
            HStack(spacing: MRSpacing.lg) {
                targetValue("Monthly ceiling", euro(housingStore.targets.maximumMonthlyCost))
                targetValue("Move-in ceiling", euro(housingStore.targets.maximumMoveInCash))
                targetValue("Minimum home", "\(housingStore.targets.minimumBedrooms) bed · \(housingStore.targets.minimumSquareMeters) m²")
            }
            .padding(.vertical, MRSpacing.sm)
            Button("Edit Milan targets") { showsTargets = true }
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("housing-edit-targets")
        }
        .padding(MRSpacing.md)
        .background(MRColor.surface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("housing-target-summary")
    }

    private func targetValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(.caption2.weight(.bold)).tracking(0.8).foregroundStyle(MRColor.secondaryText)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(MRColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var pipeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(title: "Apartment shortlist", action: filterSummary)
                .padding(.bottom, MRSpacing.sm)
            if housingStore.isLoading {
                ContentStateView(kind: .loading, title: "Loading housing", detail: "Opening the local apartment shortlist.")
            } else if let error = housingStore.error {
                ContentStateView(kind: .error, title: "Housing unavailable", detail: error)
            } else if housingStore.listings.isEmpty {
                ContentStateView(kind: .empty, title: "No listings yet", detail: "Add the first apartment to start comparing Milan homes.")
                    .accessibilityIdentifier("housing-empty-state")
            } else if filteredListings.isEmpty {
                ContentStateView(kind: .empty, title: "No matching listings", detail: "Clear or adjust the current housing filters.")
                    .accessibilityIdentifier("housing-no-results")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredListings) { listing in
                        Button { selectedListing = listing } label: {
                            HousingListingRow(listing: listing, targets: housingStore.targets)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("housing-listing-\(listing.id.uuidString)")
                        Divider().background(MRColor.divider)
                    }
                }
                .accessibilityIdentifier("housing-listings")
            }
        }
    }

    private var hasActiveFilters: Bool {
        price != .all || neighborhood != nil || qualification != nil || followUp != .all || sort != .priceLowToHigh
    }

    private var filterSummary: String {
        hasActiveFilters ? "Filtered · \(filteredListings.count)" : "\(filteredListings.count) shown"
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0 ... 2)))
    }
}

private struct HousingListingRow: View {
    let listing: ApartmentListing
    let targets: MilanHousingTargets

    var body: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(listing.address).font(.body.weight(.semibold)).foregroundStyle(MRColor.ink)
                    Text(listing.neighborhood).font(.caption).foregroundStyle(MRColor.secondaryText)
                }
                Spacer(minLength: 8)
                Text(euro(listing.totalMonthlyCost))
                    .font(.headline)
                    .foregroundStyle(listing.isWithinBudget(targets: targets) ? MRColor.ink : MRColor.red)
            }
            HStack(spacing: 8) {
                qualificationPill
                Text("\(listing.bedrooms) bed · \(listing.squareMeters) m²")
                if listing.hasElevator { Label("Elevator", systemImage: "arrow.up.arrow.down") }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(MRColor.secondaryText)
            HStack {
                Text("Move-in \(euro(listing.requiredMoveInCash))")
                Spacer()
                followUpLabel
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(MRColor.secondaryText)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens apartment editor")
    }

    private var qualificationPill: some View {
        Text(listing.qualification.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.11), in: Capsule())
    }

    @ViewBuilder private var followUpLabel: some View {
        if listing.isFollowUpOverdue() {
            Label("Follow-up overdue", systemImage: "clock.badge.exclamationmark")
                .foregroundStyle(MRColor.red)
        } else if let date = listing.nextFollowUpDate {
            Label("Follow up \(date.relocationShort)", systemImage: "calendar")
        } else {
            Text("No follow-up")
        }
    }

    private var statusColor: Color {
        switch listing.qualification {
        case .meetsRequirements: MRColor.success
        case .needsReview: MRColor.amber
        case .overBudget, .rejected: MRColor.red
        }
    }

    private var accessibilitySummary: String {
        let budget = listing.isWithinBudget(targets: targets) ? "within budget" : "outside budget"
        let followUp = listing.isFollowUpOverdue() ? ", follow-up overdue" : listing.nextFollowUpDate.map { ", follow up \($0.formatted(date: .long, time: .omitted))" } ?? ""
        return "\(listing.address), \(listing.neighborhood), \(euro(listing.totalMonthlyCost)) monthly, \(euro(listing.requiredMoveInCash)) move-in cash, \(listing.qualification.rawValue), \(budget)\(followUp)"
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0 ... 2)))
    }
}
