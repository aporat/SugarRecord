import CoreData
import Foundation

/// Represents the parent of a Core Data context.
/// It can be backed either by a persistent store coordinator or another context.
@preconcurrency public enum CoreDataContextParent: Sendable {
    case storeCoordinator(NSPersistentStoreCoordinator)
    case parentContext(NSManagedObjectContext)
}

// MARK: - Debugging

extension CoreDataContextParent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .storeCoordinator:
            return "CoreDataContextParent.storeCoordinator"
        case .parentContext:
            return "CoreDataContextParent.parentContext"
        }
    }
}

// MARK: - Equatable / Hashable

extension CoreDataContextParent: Equatable {
    public static func == (lhs: CoreDataContextParent, rhs: CoreDataContextParent) -> Bool {
        switch (lhs, rhs) {
        case (.storeCoordinator(let a), .storeCoordinator(let b)):
            return a === b
        case (.parentContext(let a), .parentContext(let b)):
            return a === b
        default:
            return false
        }
    }
}

extension CoreDataContextParent: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .storeCoordinator(let coord):
            hasher.combine(ObjectIdentifier(coord))
        case .parentContext(let ctx):
            hasher.combine(ObjectIdentifier(ctx))
        }
    }
}
