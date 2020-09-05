import CoreData
import Foundation

public enum CoreDataObjectModel {
    case named(String, Bundle)
    case merged([Bundle]?)
    case url(URL)

    func model() -> NSManagedObjectModel? {
        switch self {
        case let .merged(bundles):
            return NSManagedObjectModel.mergedModel(from: bundles)
        case let .named(name, bundle):
            return NSManagedObjectModel(contentsOf: bundle.url(forResource: name, withExtension: "momd")!)
        case let .url(url):
            return NSManagedObjectModel(contentsOf: url)
        }
    }
}

// MARK: - ObjectModel Extension (CustomStringConvertible)

extension CoreDataObjectModel: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .named(name, _): return "NSManagedObject model named: \(name) in the main NSBundle"
        case .merged: return "Merged NSManagedObjec models in the provided bundles"
        case let .url(url): return "NSManagedObject model in the URL: \(url)"
        }
    }
}

// MARK: - ObjectModel Extension (Equatable)

extension CoreDataObjectModel: Equatable {}

public func == (lhs: CoreDataObjectModel, rhs: CoreDataObjectModel) -> Bool {
    lhs.model() == rhs.model()
}
