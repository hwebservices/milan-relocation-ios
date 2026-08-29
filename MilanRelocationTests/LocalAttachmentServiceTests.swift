import XCTest
@testable import MilanRelocation

final class LocalAttachmentServiceTests: XCTestCase {
    func testImportsResolvesAndRemovesLocalFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("source/receipt.txt")
        try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("receipt".utf8).write(to: source)
        let service = LocalAttachmentService(directory: root.appendingPathComponent("attachments", isDirectory: true))
        let imported = try service.importFile(from: source)
        XCTAssertEqual(imported.byteCount, 7)
        XCTAssertNotNil(service.url(for: imported.relativePath))
        service.remove(relativePath: imported.relativePath)
        XCTAssertNil(service.url(for: imported.relativePath))
    }

    func testRestoreRejectsPathTraversal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = LocalAttachmentService(directory: directory)

        XCTAssertThrowsError(try service.restore(Data("unsafe".utf8), relativePath: "../outside.txt"))
        XCTAssertNil(service.url(for: "../outside.txt"))
    }

    func testReadsAndRestoresAttachmentData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = LocalAttachmentService(directory: directory)
        let expected = Data("document contents".utf8)

        try service.restore(expected, relativePath: "document.txt")

        XCTAssertEqual(service.data(for: "document.txt"), expected)
        XCTAssertNotNil(service.url(for: "document.txt"))
    }
}
