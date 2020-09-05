import CoreData
import Foundation

public enum CoreDataStore {
    case named(String)
    case url(URL)

    public func path() -> URL {
        switch self {
        case let .url(url): return url
        case let .named(name):
            return URL(fileURLWithPath: String.documentDirectory).appendingPathComponent(name)
        }
    }
}

// MARK: - Store extension (CustomStringConvertible)

extension CoreDataStore: CustomStringConvertible {
    public var description: String {
        "CoreData Store: \(path())"
    }
}

// MARK: - Store Extension (Equatable)

extension CoreDataStore: Equatable {}

public func == (lhs: CoreDataStore, rhs: CoreDataStore) -> Bool {
    lhs.path() == rhs.path()
}
