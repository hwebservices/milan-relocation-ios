import Foundation
import Observation

@Observable
final class MockRelocationStore {
    var documents: [DocumentItem]
    var contacts: [ContactItem]

    init() {
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
