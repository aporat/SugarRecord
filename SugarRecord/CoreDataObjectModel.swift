import CoreData
import Foundation

public enum CoreDataObjectModel {
    case named(String, Bundle)
    case merged([Bundle]?)
    case url(URL)
    
    public func model() -> NSManagedObjectModel? {
        switch self {
        case let .merged(bundles):
            return NSManagedObjectModel.mergedModel(from: bundles)
        case let .named(name, bundle):
            guard let url = bundle.url(forResource: name, withExtension: "momd") else {
                return nil
            }
            return NSManagedObjectModel(contentsOf: url)
        case let .url(url):
            return NSManagedObjectModel(contentsOf: url)
        }
    }
}

// MARK: - ObjectModel Extension (CustomStringConvertible)

extension CoreDataObjectModel: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .named(name, bundle):
            return "NSManagedObject model named: \(name) in bundle: \(bundle.bundleIdentifier ?? "unknown")"
        case .merged:
            return "Merged NSManagedObject models in the provided bundles"
        case let .url(url):
            return "NSManagedObject model at URL: \(url)"
        }
    }
}

// MARK: - ObjectModel Extension (Equatable)

extension CoreDataObjectModel: Equatable {
    public static func == (lhs: CoreDataObjectModel, rhs: CoreDataObjectModel) -> Bool {
        lhs.model() == rhs.model()
    }
}
