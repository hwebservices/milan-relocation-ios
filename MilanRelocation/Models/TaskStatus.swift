import SwiftUI

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case waitingForResponse
    case blocked
    case complete
    case cancelled

    var id: Self { self }

    var title: String {
        switch self {
        case .notStarted: "Not started"
        case .inProgress: "In progress"
        case .waitingForResponse: "Waiting for response"
        case .blocked: "Blocked"
        case .complete: "Complete"
        case .cancelled: "Cancelled"
        }
    }

    var isTerminal: Bool { self == .complete || self == .cancelled }

    var color: Color {
        switch self {
        case .notStarted: MRColor.secondaryText
        case .inProgress: MRColor.accent
        case .waitingForResponse: MRColor.amber
        case .blocked: MRColor.red
        case .complete: MRColor.success
        case .cancelled: MRColor.secondaryText
        }
    }
}

