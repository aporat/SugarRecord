import CoreData
import Foundation

/// Defines how to locate and load a Core Data object model (`.xcdatamodeld` / `.momd`).
public enum CoreDataObjectModel: Sendable {
    /// A model stored in a named `.momd` resource inside a bundle.
    case named(String, Bundle)
    /// Merge all models found in the given bundles (or all bundles if `nil`).
    case merged([Bundle]?)
    /// A model at an explicit file URL.
    case url(URL)
    
    /// Load the managed object model from the source.
    public func load() -> NSManagedObjectModel? {
        switch self {
        case .merged(let bundles):
            return NSManagedObjectModel.mergedModel(from: bundles)
        case .named(let name, let bundle):
            guard let url = bundle.url(forResource: name, withExtension: "momd") else {
                return nil
            }
            return NSManagedObjectModel(contentsOf: url)
        case .url(let url):
            return NSManagedObjectModel(contentsOf: url)
        }
    }
}

// MARK: - CustomStringConvertible

extension CoreDataObjectModel: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .named(name, bundle):
            return "CoreDataObjectModel.named(\(name), bundle: \(bundle.bundleIdentifier ?? "unknown"))"
        case .merged:
            return "CoreDataObjectModel.merged(bundles)"
        case let .url(url):
            return "CoreDataObjectModel.url(\(url.path))"
        }
    }
}

// MARK: - Equatable

extension CoreDataObjectModel: Equatable {
    public static func == (lhs: CoreDataObjectModel, rhs: CoreDataObjectModel) -> Bool {
        lhs.load() == rhs.load()
    }
}
