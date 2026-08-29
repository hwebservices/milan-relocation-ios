import Foundation
import Observation

@Observable
final class MockRelocationStore {
    var timeline: [TimelineItem]
    var budget: [BudgetItem]
    var documents: [DocumentItem]
    var contacts: [ContactItem]

    init(calendar: Calendar = .current, now: Date = .now) {
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now) ?? now }

        timeline = [
            TimelineItem(title: "Documents & eligibility", category: "Preparation", owner: .both, startDate: day(-30), endDate: day(28), progress: 0.58),
            TimelineItem(title: "Housing search", category: "Home", owner: .both, startDate: day(-8), endDate: day(65), progress: 0.24),
            TimelineItem(title: "Work transition", category: "Career", owner: .henry, startDate: day(10), endDate: day(80), progress: 0.08),
            TimelineItem(title: "Move & settle in", category: "Arrival", owner: .both, startDate: day(72), endDate: day(110), progress: 0)
        ]

        budget = [
            BudgetItem(category: "Housing & deposits", planned: 16000, actual: 4200),
            BudgetItem(category: "Legal & documents", planned: 2500, actual: 860),
            BudgetItem(category: "Travel", planned: 5000, actual: 1750),
            BudgetItem(category: "Moving", planned: 7500, actual: 900),
            BudgetItem(category: "Arrival buffer", planned: 9000, actual: 0)
        ]

        documents = [
            DocumentItem(name: "Passports", category: "Identity", owner: .both, isReady: true),
            DocumentItem(name: "Marriage certificate", category: "Civil records", owner: .henry, isReady: false),
            DocumentItem(name: "Employment letters", category: "Work", owner: .both, isReady: true),
            DocumentItem(name: "Health insurance evidence", category: "Health", owner: .jeff, isReady: false)
        ]

        contacts = [
            ContactItem(name: "Giulia Bianchi", role: "Relocation consultant", organization: "Milano Welcome", email: "giulia@example.com"),
            ContactItem(name: "Luca Romano", role: "Property advisor", organization: "Casa Milano", email: "luca@example.com"),
            ContactItem(name: "Elena Conti", role: "Immigration attorney", organization: "Conti Legal", email: "elena@example.com")
        ]
    }
}
