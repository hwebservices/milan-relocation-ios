import Foundation

enum FurnishedStatus: String, Codable, CaseIterable, Identifiable {
    case unfurnished = "Unfurnished"
    case partiallyFurnished = "Partially furnished"
    case furnished = "Furnished"

    var id: Self { self }
}

enum HousingContractType: String, Codable, CaseIterable, Identifiable {
    case transitory = "Transitory"
    case fourPlusFour = "4+4"
    case threePlusTwo = "3+2"
    case other = "Other"

    var id: Self { self }
}

enum HousingQualification: String, Codable, CaseIterable, Identifiable {
    case meetsRequirements = "Meets requirements"
    case needsReview = "Needs review"
    case overBudget = "Over budget"
    case rejected = "Rejected"

    var id: Self { self }

    var accessibilityID: String {
        switch self {
        case .meetsRequirements: "meets-requirements"
        case .needsReview: "needs-review"
        case .overBudget: "over-budget"
        case .rejected: "rejected"
        }
    }
}

enum HousingContactMethod: String, Codable, CaseIterable, Identifiable {
    case email = "Email"
    case phone = "Phone"
    case whatsapp = "WhatsApp"
    case portal = "Listing portal"

    var id: Self { self }
}

struct HousingContactAttempt: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var method: HousingContactMethod
    var response: String?
    var responseDate: Date?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        method: HousingContactMethod = .email,
        response: String? = nil,
        responseDate: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.method = method
        self.response = response
        self.responseDate = responseDate
    }
}

struct HousingPriceChange: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var previousRent: Decimal
    var newRent: Decimal

    init(id: UUID = UUID(), date: Date = .now, previousRent: Decimal, newRent: Decimal) {
        self.id = id
        self.date = date
        self.previousRent = previousRent
        self.newRent = newRent
    }
}

struct MilanHousingTargets: Codable, Hashable {
    var maximumMonthlyCost: Decimal
    var maximumMoveInCash: Decimal
    var minimumBedrooms: Int
    var minimumSquareMeters: Int
    var requiresElevator: Bool
    var furnishedPreference: FurnishedStatus?
}

struct ApartmentListing: Identifiable, Codable, Hashable {
    let id: UUID
    var address: String
    var neighborhood: String
    var listingURL: String
    var rent: Decimal
    var condominio: Decimal
    var utilitiesEstimate: Decimal
    var bedrooms: Int
    var squareMeters: Int
    var hasElevator: Bool
    var furnishedStatus: FurnishedStatus
    var contractType: HousingContractType
    var availabilityDate: Date
    var deposit: Decimal
    var agencyFee: Decimal
    var otherMoveInCosts: Decimal
    var qualification: HousingQualification
    var contactAttempts: [HousingContactAttempt]
    var nextFollowUpDate: Date?
    var priceHistory: [HousingPriceChange]
    var notes: String?

    init(
        id: UUID = UUID(),
        address: String,
        neighborhood: String,
        listingURL: String = "",
        rent: Decimal,
        condominio: Decimal = 0,
        utilitiesEstimate: Decimal = 0,
        bedrooms: Int = 1,
        squareMeters: Int = 50,
        hasElevator: Bool = false,
        furnishedStatus: FurnishedStatus = .furnished,
        contractType: HousingContractType = .fourPlusFour,
        availabilityDate: Date = .now,
        deposit: Decimal = 0,
        agencyFee: Decimal = 0,
        otherMoveInCosts: Decimal = 0,
        qualification: HousingQualification = .needsReview,
        contactAttempts: [HousingContactAttempt] = [],
        nextFollowUpDate: Date? = nil,
        priceHistory: [HousingPriceChange] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.address = address
        self.neighborhood = neighborhood
        self.listingURL = listingURL
        self.rent = rent
        self.condominio = condominio
        self.utilitiesEstimate = utilitiesEstimate
        self.bedrooms = bedrooms
        self.squareMeters = squareMeters
        self.hasElevator = hasElevator
        self.furnishedStatus = furnishedStatus
        self.contractType = contractType
        self.availabilityDate = availabilityDate
        self.deposit = deposit
        self.agencyFee = agencyFee
        self.otherMoveInCosts = otherMoveInCosts
        self.qualification = qualification
        self.contactAttempts = contactAttempts
        self.nextFollowUpDate = nextFollowUpDate
        self.priceHistory = priceHistory
        self.notes = notes
    }

    var totalMonthlyCost: Decimal { rent + condominio + utilitiesEstimate }

    var requiredMoveInCash: Decimal {
        deposit + agencyFee + totalMonthlyCost + otherMoveInCosts
    }

    func isWithinBudget(targets: MilanHousingTargets) -> Bool {
        totalMonthlyCost <= targets.maximumMonthlyCost && requiredMoveInCash <= targets.maximumMoveInCash
    }

    func meetsRequirements(targets: MilanHousingTargets) -> Bool {
        bedrooms >= targets.minimumBedrooms
            && squareMeters >= targets.minimumSquareMeters
            && (!targets.requiresElevator || hasElevator)
            && (targets.furnishedPreference == nil || furnishedStatus == targets.furnishedPreference)
    }

    func isFollowUpOverdue(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard qualification != .rejected, let nextFollowUpDate else { return false }
        return calendar.startOfDay(for: nextFollowUpDate) < calendar.startOfDay(for: referenceDate)
    }
}

struct HousingData: Codable, Hashable {
    var listings: [ApartmentListing]
    var targets: MilanHousingTargets
}

enum HousingSort: String, CaseIterable, Identifiable {
    case priceLowToHigh = "Price: low to high"
    case priceHighToLow = "Price: high to low"
    case neighborhood = "Neighborhood"
    case status = "Status"
    case followUp = "Follow-up"

    var id: Self { self }
}

enum HousingFollowUpFilter: String, CaseIterable, Identifiable {
    case all = "All follow-ups"
    case overdue = "Overdue"
    case scheduled = "Scheduled"
    case none = "No follow-up"

    var id: Self { self }
}

enum HousingPriceFilter: String, CaseIterable, Identifiable {
    case all = "All prices"
    case withinTarget = "Within price target"
    case aboveTarget = "Above price target"

    var id: Self { self }
}
