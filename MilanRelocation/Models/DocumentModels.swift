import Foundation

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case identity = "Identity"
    case education = "Education"
    case nursing = "Nursing"
    case employment = "Employment"
    case residency = "Residency"
    case financial = "Financial"
    case other = "Other"

    var id: Self { self }
}

enum DocumentStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "Not started"
    case requested = "Requested"
    case received = "Received"
    case translationNeeded = "Translation needed"
    case complete = "Complete"
    case expired = "Expired"
    case notApplicable = "Not applicable"

    var id: Self { self }
    var isResolved: Bool { self == .complete || self == .notApplicable }
}

struct DocumentAttachmentMetadata: Identifiable, Codable, Hashable {
    let id: UUID
    var fileName: String
    var contentType: String
    var byteCount: Int?
    var addedAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        contentType: String = "application/octet-stream",
        byteCount: Int? = nil,
        addedAt: Date = .now
    ) {
        self.id = id
        self.fileName = fileName
        self.contentType = contentType
        self.byteCount = byteCount
        self.addedAt = addedAt
    }
}

struct RelocationDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var owner: TaskOwner
    var category: DocumentCategory
    var status: DocumentStatus
    var issueDate: Date?
    var expirationDate: Date?
    var requiredFor: String
    var notes: String?
    var sourceInformation: String?
    var attachments: [DocumentAttachmentMetadata]
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        owner: TaskOwner,
        category: DocumentCategory,
        status: DocumentStatus,
        issueDate: Date? = nil,
        expirationDate: Date? = nil,
        requiredFor: String = "",
        notes: String? = nil,
        sourceInformation: String? = nil,
        attachments: [DocumentAttachmentMetadata] = [],
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.owner = owner
        self.category = category
        self.status = status
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.requiredFor = requiredFor
        self.notes = notes
        self.sourceInformation = sourceInformation
        self.attachments = attachments
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func effectiveStatus(referenceDate: Date = .now, calendar: Calendar = .current) -> DocumentStatus {
        isExpired(referenceDate: referenceDate, calendar: calendar) ? .expired : status
    }

    func isExpired(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard status != .notApplicable else { return false }
        if status == .expired { return true }
        guard let expirationDate else { return false }
        return calendar.startOfDay(for: expirationDate) < calendar.startOfDay(for: referenceDate)
    }

    func isExpiringSoon(
        referenceDate: Date = .now,
        withinDays days: Int = 60,
        calendar: Calendar = .current
    ) -> Bool {
        guard status != .notApplicable, !isExpired(referenceDate: referenceDate, calendar: calendar),
              let expirationDate,
              let threshold = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: referenceDate))
        else { return false }
        return calendar.startOfDay(for: expirationDate) <= threshold
    }

    func isMissing(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        switch effectiveStatus(referenceDate: referenceDate, calendar: calendar) {
        case .notStarted, .requested, .translationNeeded: true
        case .received, .complete, .expired, .notApplicable: false
        }
    }
}
