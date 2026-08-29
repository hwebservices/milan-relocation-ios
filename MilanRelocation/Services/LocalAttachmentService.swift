import Foundation

struct LocalAttachmentService {
    private let directory: URL

    init(directory: URL? = nil, fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.directory = directory ?? base.appendingPathComponent("MilanRelocation/Attachments", isDirectory: true)
    }

    func importFile(from source: URL, fileManager: FileManager = .default) throws -> (relativePath: String, byteCount: Int?) {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let accessed = source.startAccessingSecurityScopedResource()
        defer { if accessed { source.stopAccessingSecurityScopedResource() } }
        let safeName = source.lastPathComponent.replacingOccurrences(of: "/", with: "-")
        let relativePath = "\(UUID().uuidString)-\(safeName)"
        let destination = directory.appendingPathComponent(relativePath)
        try fileManager.copyItem(at: source, to: destination)
        let values = try? destination.resourceValues(forKeys: [.fileSizeKey])
        return (relativePath, values?.fileSize)
    }

    func url(for relativePath: String?) -> URL? {
        guard let relativePath, let url = try? destinationURL(for: relativePath) else { return nil }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func remove(relativePath: String?) {
        guard let url = url(for: relativePath) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    func data(for relativePath: String) -> Data? { url(for: relativePath).flatMap { try? Data(contentsOf: $0) } }

    func restore(_ data: Data, relativePath: String, fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: destinationURL(for: relativePath), options: .atomic)
    }

    private func destinationURL(for relativePath: String) throws -> URL {
        guard !relativePath.isEmpty,
              relativePath != ".",
              relativePath != "..",
              (relativePath as NSString).lastPathComponent == relativePath,
              !relativePath.contains("\\")
        else { throw CocoaError(.fileWriteInvalidFileName) }
        return directory.appendingPathComponent(relativePath, isDirectory: false)
    }
}
