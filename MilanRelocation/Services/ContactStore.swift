import Foundation
import Observation

protocol ContactPersistence {
    func load() throws -> [ContactItem]?
    func save(_ contacts: [ContactItem]) throws
}

struct FileContactPersistence: ContactPersistence {
    let url: URL

    func load() throws -> [ContactItem]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode([ContactItem].self, from: Data(contentsOf: url))
    }

    func save(_ contacts: [ContactItem]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(contacts).write(to: url, options: .atomic)
    }

    static func appStorage(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let name = environment["MILAN_UI_TESTING"] == "1" ? "ui-test-contacts.json" : "contacts.json"
        return Self(url: base.appendingPathComponent("MilanRelocation", isDirectory: true).appendingPathComponent(name))
    }
}

@MainActor @Observable
final class ContactStore {
    private(set) var contacts: [ContactItem]
    private(set) var error: String?
    private let persistence: ContactPersistence

    init(persistence: ContactPersistence, seedContacts: [ContactItem] = []) {
        self.persistence = persistence
        do {
            if let saved = try persistence.load() { contacts = saved }
            else { contacts = seedContacts; try persistence.save(seedContacts) }
        } catch { contacts = seedContacts; self.error = "Contacts could not be loaded. Changes may not persist." }
        sort()
    }

    static func live(environment: [String: String] = ProcessInfo.processInfo.environment) -> ContactStore {
        let persistence = FileContactPersistence.appStorage(environment: environment)
        if environment["MILAN_RESET_CONTACTS"] == "1" { try? FileManager.default.removeItem(at: persistence.url) }
        let seed = environment["MILAN_UI_TESTING"] == "1" ? samples : []
        return ContactStore(persistence: persistence, seedContacts: seed)
    }

    func create(_ contact: ContactItem) { contacts.append(contact); commit() }
    func update(_ contact: ContactItem) { guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }; contacts[index] = contact; commit() }
    func delete(id: UUID) { contacts.removeAll { $0.id == id }; commit() }
    func replaceAll(with contacts: [ContactItem]) { self.contacts = contacts; commit() }

    private func commit() {
        sort()
        do { try persistence.save(contacts); error = nil }
        catch { self.error = "Contacts could not be saved. Please try again." }
    }
    private func sort() { contacts.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }

    static let samples = [
        ContactItem(name: "Giulia Bianchi", role: "Relocation consultant", organization: "Milano Welcome", email: "giulia@example.com"),
        ContactItem(name: "Luca Romano", role: "Property advisor", organization: "Casa Milano", email: "luca@example.com"),
        ContactItem(name: "Elena Conti", role: "Immigration attorney", organization: "Conti Legal", email: "elena@example.com")
    ]
}
