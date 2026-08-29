import XCTest
@testable import MilanRelocation

@MainActor
final class ContactStoreTests: XCTestCase {
    func testCreateEditDeleteAndPersistence() {
        let persistence = MemoryContactPersistence()
        let store = ContactStore(persistence: persistence)
        var contact = ContactItem(name: "Mario Rossi", role: "Agent", organization: "Casa", email: "mario@example.com")
        store.create(contact)
        XCTAssertEqual(persistence.contacts?.first?.name, "Mario Rossi")
        contact.phone = "+39 02 1234"
        store.update(contact)
        XCTAssertEqual(store.contacts.first?.phone, "+39 02 1234")
        let relaunched = ContactStore(persistence: persistence)
        XCTAssertEqual(relaunched.contacts.first?.email, "mario@example.com")
        relaunched.delete(id: contact.id)
        XCTAssertTrue(relaunched.contacts.isEmpty)
    }
}

private final class MemoryContactPersistence: ContactPersistence {
    var contacts: [ContactItem]?
    func load() throws -> [ContactItem]? { contacts }
    func save(_ contacts: [ContactItem]) throws { self.contacts = contacts }
}
