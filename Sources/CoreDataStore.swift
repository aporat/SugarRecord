@preconcurrency import CoreData
import Foundation

// MARK: - Fileprivate Helpers

fileprivate extension URL {
    /// The app’s document directory.
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// MARK: - CoreDataStore

/// Identifies a Core Data store location.
@frozen public enum CoreDataStore: Sendable, Equatable, Hashable {
    case named(String)
    case url(URL)
    case inMemory
    
    /// The resolved URL of the store.
    public var path: URL? {
        switch self {
        case .url(let url):
            return url
        case .named(let name):
            return URL.documentDirectory.appendingPathComponent(name)
        case .inMemory:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension CoreDataStore: CustomStringConvertible {
    public var description: String {
        switch self {
        case .named(let name):
            return "CoreDataStore(named: \(name)) → \(path?.path ?? "nil")"
        case .url(let url):
            return "CoreDataStore(url: \(url.path))"
        case .inMemory:
            return "CoreDataStore(inMemory)"
        }
    }
}
