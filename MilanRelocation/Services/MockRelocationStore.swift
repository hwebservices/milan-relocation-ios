import Foundation
import Observation

@Observable
final class MockRelocationStore {
    var contacts: [ContactItem]

    init() {
        contacts = [
            ContactItem(name: "Giulia Bianchi", role: "Relocation consultant", organization: "Milano Welcome", email: "giulia@example.com"),
            ContactItem(name: "Luca Romano", role: "Property advisor", organization: "Casa Milano", email: "luca@example.com"),
            ContactItem(name: "Elena Conti", role: "Immigration attorney", organization: "Conti Legal", email: "elena@example.com")
        ]
    }
}
