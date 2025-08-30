import CoreData
import Foundation

/// Represents the parent of a Core Data context.
/// It can be backed either by a persistent store coordinator or another context.
public enum CoreDataContextParent {
    case coordinator(NSPersistentStoreCoordinator)
    case context(NSManagedObjectContext)
}

// MARK: - Debugging

extension CoreDataContextParent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .coordinator:
            return "CoreDataContextParent.coordinator"
        case .context:
            return "CoreDataContextParent.context"
        }
    }
}

// MARK: - Equatable / Hashable

extension CoreDataContextParent: Equatable {
    public static func == (lhs: CoreDataContextParent, rhs: CoreDataContextParent) -> Bool {
        switch (lhs, rhs) {
        case (.coordinator(let a), .coordinator(let b)):
            return a === b
        case (.context(let a), .context(let b)):
            return a === b
        default:
            return false
        }
    }
}

extension CoreDataContextParent: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .coordinator(let coord):
            hasher.combine(ObjectIdentifier(coord))
        case .context(let ctx):
            hasher.combine(ObjectIdentifier(ctx))
        }
    }
}
