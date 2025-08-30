import CoreData
import Foundation

public enum CoreDataStore {
    case named(String)
    case url(URL)

    public func path() -> URL {
        switch self {
        case let .url(url):
            return url
        case let .named(name):
            return URL.documentDirectory.appendingPathComponent(name)
        }
    }
}

// MARK: - Store extension (CustomStringConvertible)

extension CoreDataStore: CustomStringConvertible {
    public var description: String {
        switch self {
        case .named(let name): return "CoreData Store (named: \(name)) @ \(path())"
        case .url(let url):    return "CoreData Store (url) @ \(url)"
        }
    }
}

// MARK: - Conformances

extension CoreDataStore: Equatable {}
extension CoreDataStore: Hashable {}


// MARK: - Helpers

extension URL {
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
