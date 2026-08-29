import Foundation
import Observation

protocol HousingPersistence: AnyObject {
    func load() throws -> HousingData?
    func save(_ data: HousingData) throws
}

final class FileHousingPersistence: HousingPersistence {
    private let fileURL: URL

    init(fileURL: URL) { self.fileURL = fileURL }

    static func live() -> FileHousingPersistence {
        let manager = FileManager.default
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("MilanRelocation", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = ProcessInfo.processInfo.environment["MILAN_UI_TESTING"] == "1"
            ? "ui-test-housing.json" : "housing.json"
        return FileHousingPersistence(fileURL: directory.appendingPathComponent(fileName))
    }

    func load() throws -> HousingData? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try JSONDecoder().decode(HousingData.self, from: Data(contentsOf: fileURL))
    }

    func save(_ data: HousingData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(data).write(to: fileURL, options: .atomic)
    }
}

@MainActor
@Observable
final class HousingStore {
    private(set) var data: HousingData
    private(set) var isLoading = false
    private(set) var error: String?

    private let persistence: HousingPersistence
    private let calendar: Calendar

    var listings: [ApartmentListing] { data.listings }
    var targets: MilanHousingTargets { data.targets }

    init(persistence: HousingPersistence, seedData: HousingData, calendar: Calendar = .current) {
        self.persistence = persistence
        self.calendar = calendar
        data = seedData
        load()
    }

    static func live() -> HousingStore {
        let persistence = FileHousingPersistence.live()
        let isUITesting = ProcessInfo.processInfo.environment["MILAN_UI_TESTING"] == "1"
        let seed = isUITesting ? sampleData : emptyData
        if ProcessInfo.processInfo.environment["MILAN_RESET_HOUSING"] == "1" {
            try? persistence.save(seed)
        }
        return HousingStore(persistence: persistence, seedData: seed)
    }

    func create(_ listing: ApartmentListing) {
        data.listings.append(listing)
        normalizeAndSave()
    }

    func update(_ listing: ApartmentListing, changeDate: Date = .now) {
        guard let index = data.listings.firstIndex(where: { $0.id == listing.id }) else { return }
        var updated = listing
        let previous = data.listings[index]
        if previous.rent != listing.rent {
            updated.priceHistory.append(
                HousingPriceChange(date: changeDate, previousRent: previous.rent, newRent: listing.rent)
            )
        }
        data.listings[index] = updated
        normalizeAndSave()
    }

    func delete(id: UUID) {
        data.listings.removeAll { $0.id == id }
        save()
    }

    func updateTargets(_ targets: MilanHousingTargets) {
        data.targets = targets
        save()
    }

    func replaceAll(with data: HousingData) { self.data = data; normalizeAndSave() }

    func filteredListings(
        sort: HousingSort,
        price: HousingPriceFilter,
        neighborhood: String?,
        qualification: HousingQualification?,
        followUp: HousingFollowUpFilter,
        referenceDate: Date = .now
    ) -> [ApartmentListing] {
        data.listings
            .filter { listing in
                switch price {
                case .all: true
                case .withinTarget: listing.isWithinBudget(targets: data.targets)
                case .aboveTarget: !listing.isWithinBudget(targets: data.targets)
                }
            }
            .filter { neighborhood == nil || $0.neighborhood == neighborhood }
            .filter { qualification == nil || $0.qualification == qualification }
            .filter { listing in
                switch followUp {
                case .all: true
                case .overdue: listing.isFollowUpOverdue(referenceDate: referenceDate, calendar: calendar)
                case .scheduled: listing.nextFollowUpDate != nil
                case .none: listing.nextFollowUpDate == nil
                }
            }
            .sorted { lhs, rhs in
                switch sort {
                case .priceLowToHigh: lhs.totalMonthlyCost < rhs.totalMonthlyCost
                case .priceHighToLow: lhs.totalMonthlyCost > rhs.totalMonthlyCost
                case .neighborhood: lhs.neighborhood.localizedCaseInsensitiveCompare(rhs.neighborhood) == .orderedAscending
                case .status: lhs.qualification.rawValue < rhs.qualification.rawValue
                case .followUp:
                    (lhs.nextFollowUpDate ?? .distantFuture) < (rhs.nextFollowUpDate ?? .distantFuture)
                }
            }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            if let stored = try persistence.load() { data = stored }
            normalize()
            error = nil
        } catch {
            self.error = "Housing data could not be loaded. Please try again."
        }
    }

    private func normalizeAndSave() {
        normalize()
        save()
    }

    private func normalize() {
        data.listings.sort { $0.address.localizedCaseInsensitiveCompare($1.address) == .orderedAscending }
    }

    private func save() {
        do {
            try persistence.save(data)
            error = nil
        } catch {
            self.error = "Housing changes could not be saved on this device."
        }
    }

    static let sampleData = HousingData(
        listings: [
            ApartmentListing(
                address: "Via Orti 12",
                neighborhood: "Porta Romana",
                listingURL: "https://example.com/via-orti-12",
                rent: 1_850,
                condominio: 180,
                utilitiesEstimate: 160,
                bedrooms: 2,
                squareMeters: 82,
                hasElevator: true,
                furnishedStatus: .furnished,
                contractType: .fourPlusFour,
                availabilityDate: Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 10))!,
                deposit: 5_550,
                agencyFee: 2_257,
                otherMoveInCosts: 350,
                qualification: .meetsRequirements,
                contactAttempts: [HousingContactAttempt(date: .now, method: .email, response: "Viewing available next week", responseDate: .now)],
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)
            ),
            ApartmentListing(
                address: "Corso Lodi 48",
                neighborhood: "Lodi",
                listingURL: "https://example.com/corso-lodi-48",
                rent: 1_650,
                condominio: 220,
                utilitiesEstimate: 170,
                bedrooms: 2,
                squareMeters: 76,
                hasElevator: true,
                furnishedStatus: .partiallyFurnished,
                contractType: .threePlusTwo,
                availabilityDate: Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 15))!,
                deposit: 4_950,
                agencyFee: 2_013,
                otherMoveInCosts: 250,
                qualification: .needsReview,
                contactAttempts: [HousingContactAttempt(date: Calendar.current.date(byAdding: .day, value: -6, to: .now)!, method: .whatsapp)],
                nextFollowUpDate: Calendar.current.date(byAdding: .day, value: -2, to: .now)
            ),
            ApartmentListing(
                address: "Via Savona 31",
                neighborhood: "Navigli",
                listingURL: "https://example.com/via-savona-31",
                rent: 2_350,
                condominio: 240,
                utilitiesEstimate: 190,
                bedrooms: 2,
                squareMeters: 88,
                hasElevator: false,
                furnishedStatus: .furnished,
                contractType: .transitory,
                availabilityDate: Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1))!,
                deposit: 7_050,
                agencyFee: 2_867,
                otherMoveInCosts: 450,
                qualification: .overBudget
            )
        ],
        targets: MilanHousingTargets(
            maximumMonthlyCost: 2_400,
            maximumMoveInCash: 11_500,
            minimumBedrooms: 2,
            minimumSquareMeters: 75,
            requiresElevator: true,
            furnishedPreference: .furnished
        )
    )

    static let emptyData = HousingData(
        listings: [],
        targets: MilanHousingTargets(maximumMonthlyCost: 0, maximumMoveInCash: 0, minimumBedrooms: 0, minimumSquareMeters: 0, requiresElevator: false, furnishedPreference: .unfurnished)
    )
}
