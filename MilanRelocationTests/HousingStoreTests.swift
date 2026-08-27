import XCTest
@testable import MilanRelocation

@MainActor
final class HousingStoreTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testMonthlyAndMoveInCostCalculations() {
        let listing = makeListing(rent: 1_800, condominio: 180, utilities: 140, deposit: 5_400, agencyFee: 2_196, otherCosts: 300)

        XCTAssertEqual(listing.totalMonthlyCost, 2_120)
        XCTAssertEqual(listing.requiredMoveInCash, 10_016)
    }

    func testBudgetAndRequirementsQualificationUsesEditableTargets() {
        let listing = makeListing(rent: 1_800, condominio: 180, utilities: 140)
        let qualifyingTargets = targets(maximumMonthly: 2_200, maximumMoveIn: 10_000)
        let tightTargets = targets(maximumMonthly: 2_000, maximumMoveIn: 10_000)

        XCTAssertTrue(listing.isWithinBudget(targets: qualifyingTargets))
        XCTAssertTrue(listing.meetsRequirements(targets: qualifyingTargets))
        XCTAssertFalse(listing.isWithinBudget(targets: tightTargets))

        var noElevator = listing
        noElevator.hasElevator = false
        XCTAssertFalse(noElevator.meetsRequirements(targets: qualifyingTargets))
    }

    func testFollowUpOverdueExcludesTodayFutureAndRejectedListings() {
        let reference = date(2026, 8, 27)
        var listing = makeListing()
        listing.nextFollowUpDate = date(2026, 8, 26)
        XCTAssertTrue(listing.isFollowUpOverdue(referenceDate: reference, calendar: calendar))

        listing.nextFollowUpDate = reference
        XCTAssertFalse(listing.isFollowUpOverdue(referenceDate: reference, calendar: calendar))
        listing.nextFollowUpDate = date(2026, 8, 28)
        XCTAssertFalse(listing.isFollowUpOverdue(referenceDate: reference, calendar: calendar))
        listing.nextFollowUpDate = date(2026, 8, 26)
        listing.qualification = .rejected
        XCTAssertFalse(listing.isFollowUpOverdue(referenceDate: reference, calendar: calendar))
    }

    func testRentEditAddsPriceHistoryAndPersists() {
        let persistence = MemoryHousingPersistence()
        let original = makeListing(rent: 1_800)
        let store = HousingStore(persistence: persistence, seedData: HousingData(listings: [original], targets: targets()))
        var edited = original
        edited.rent = 1_700

        store.update(edited, changeDate: date(2026, 8, 27))
        let relaunched = HousingStore(persistence: persistence, seedData: HousingData(listings: [], targets: targets()))

        XCTAssertEqual(relaunched.listings.first?.rent, 1_700)
        XCTAssertEqual(relaunched.listings.first?.priceHistory.count, 1)
        XCTAssertEqual(relaunched.listings.first?.priceHistory.first?.previousRent, 1_800)
        XCTAssertEqual(relaunched.listings.first?.priceHistory.first?.newRent, 1_700)
    }

    func testFilteringAndSortingByPipelineCriteria() {
        var overdue = makeListing(address: "B", neighborhood: "Navigli", rent: 2_600, qualification: .overBudget)
        overdue.nextFollowUpDate = date(2026, 8, 20)
        let match = makeListing(address: "A", neighborhood: "Porta Romana", rent: 1_700, qualification: .meetsRequirements)
        let store = HousingStore(
            persistence: MemoryHousingPersistence(),
            seedData: HousingData(listings: [overdue, match], targets: targets()),
            calendar: calendar
        )

        let filtered = store.filteredListings(
            sort: .priceHighToLow,
            price: .all,
            neighborhood: "Navigli",
            qualification: .overBudget,
            followUp: .overdue,
            referenceDate: date(2026, 8, 27)
        )

        XCTAssertEqual(filtered.map(\.id), [overdue.id])
        XCTAssertEqual(
            store.filteredListings(sort: .priceLowToHigh, price: .all, neighborhood: nil, qualification: nil, followUp: .all).map(\.id),
            [match.id, overdue.id]
        )
        XCTAssertEqual(
            store.filteredListings(sort: .priceLowToHigh, price: .aboveTarget, neighborhood: nil, qualification: nil, followUp: .all).map(\.id),
            [overdue.id]
        )
    }

    private func makeListing(
        address: String = "Via Orti 12",
        neighborhood: String = "Porta Romana",
        rent: Decimal = 1_800,
        condominio: Decimal = 0,
        utilities: Decimal = 0,
        deposit: Decimal = 0,
        agencyFee: Decimal = 0,
        otherCosts: Decimal = 0,
        qualification: HousingQualification = .needsReview
    ) -> ApartmentListing {
        ApartmentListing(
            address: address, neighborhood: neighborhood, rent: rent, condominio: condominio,
            utilitiesEstimate: utilities, bedrooms: 2, squareMeters: 80, hasElevator: true,
            furnishedStatus: .furnished, deposit: deposit, agencyFee: agencyFee,
            otherMoveInCosts: otherCosts, qualification: qualification
        )
    }

    private func targets(
        maximumMonthly: Decimal = 2_500,
        maximumMoveIn: Decimal = 20_000
    ) -> MilanHousingTargets {
        MilanHousingTargets(
            maximumMonthlyCost: maximumMonthly, maximumMoveInCash: maximumMoveIn,
            minimumBedrooms: 2, minimumSquareMeters: 75, requiresElevator: true,
            furnishedPreference: .furnished
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

private final class MemoryHousingPersistence: HousingPersistence {
    var storedData: HousingData?
    func load() throws -> HousingData? { storedData }
    func save(_ data: HousingData) throws { storedData = data }
}
