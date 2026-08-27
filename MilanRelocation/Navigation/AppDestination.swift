import SwiftUI

enum AppDestination: String, CaseIterable, Identifiable {
    case today, tasks, timeline, budget, housing, educationWork, documents, contacts, weeklyReview, settings

    var id: Self { self }
    var title: String {
        switch self {
        case .today: "Today"
        case .tasks: "Tasks"
        case .timeline: "Timeline"
        case .budget: "Budget"
        case .housing: "Housing"
        case .educationWork: "Education & Work"
        case .documents: "Documents"
        case .contacts: "Contacts"
        case .weeklyReview: "Weekly Review"
        case .settings: "Settings"
        }
    }
    var icon: String {
        switch self {
        case .today: "sparkles"
        case .tasks: "checklist"
        case .timeline: "chart.bar.xaxis"
        case .budget: "eurosign.circle"
        case .housing: "house"
        case .educationWork: "briefcase"
        case .documents: "doc.text"
        case .contacts: "person.2"
        case .weeklyReview: "calendar.badge.checkmark"
        case .settings: "gearshape"
        }
    }
}

