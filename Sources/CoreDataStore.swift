import CoreData
import Foundation

/// Identifies a Core Data store location.
public enum CoreDataStore: Sendable {
    case named(String)
    case url(URL)

    /// The resolved URL of the store.
    public var path: URL {
        switch self {
        case .url(let url):
            return url
        case .named(let name):
            return URL.documentDirectory.appendingPathComponent(name)
        }
    }
}

// MARK: - Store extension (CustomStringConvertible)

extension CoreDataStore: CustomStringConvertible {
    public var description: String {
        switch self {
        case .named(let name):
            return "CoreDataStore(named: \(name)) → \(path.path)"
        case .url(let url):
            return "CoreDataStore(url: \(url.path))"
        }
    }
}

// MARK: - Conformances

extension CoreDataStore: Equatable {}
extension CoreDataStore: Hashable {}

// MARK: - Helpers

extension URL {
    /// The app’s document directory.
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
