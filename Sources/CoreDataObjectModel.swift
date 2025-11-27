@preconcurrency import CoreData
import Foundation

/// Defines how to locate and load a Core Data object model (`.xcdatamodeld` / `.momd`).
@frozen public enum CoreDataObjectModel: @unchecked Sendable {
    /// A model stored in a named `.momd` resource inside a bundle.
    case named(String, Bundle)
    /// Merge all models found in the given bundles (or all bundles if `nil`).
    case merged([Bundle]?)
    /// A model at an explicit file URL.
    case url(URL)
    /// An explicit model instance (useful for in-memory unit tests).
    case model(NSManagedObjectModel)
    
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
        case .model(let model):
            return model
        }
    }
}

// MARK: - CustomStringConvertible

extension CoreDataObjectModel: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .named(name, bundle):
            return "CoreDataObjectModel.named(\(name), bundle: \(bundle.bundleIdentifier ?? "unknown"))"
        case .merged(let bundles):
            let bundleNames = (bundles ?? Bundle.allBundles).compactMap(\.bundleIdentifier).joined(separator: ", ")
            return "CoreDataObjectModel.merged(bundles: [\(bundleNames)])"
        case let .url(url):
            return "CoreDataObjectModel.url(\(url.path))"
        case .model:
            return "CoreDataObjectModel.model(<NSManagedObjectModel>)"
        }
    }
}

// MARK: - Equatable

extension CoreDataObjectModel: Equatable {
    public static func == (lhs: CoreDataObjectModel, rhs: CoreDataObjectModel) -> Bool {
        // We compare the loaded models because we cannot equate the definitions easily
        // if one is a file and one is an object instance.
        lhs.load() == rhs.load()
    }
}

// MARK: - Hashable

extension CoreDataObjectModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(load())
    }
}
