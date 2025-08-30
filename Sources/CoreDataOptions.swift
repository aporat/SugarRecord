import CoreData
import Foundation

/// Standard Core Data persistent store options.
public enum CoreDataOptions: Sendable {
    case basic
    case migration
    
    /// Store configuration dictionary for NSPersistentStoreCoordinator.
    public var settings: [String: Any] {
        switch self {
        case .basic:
            return CoreDataOptions.makeOptions(inferMapping: false)
        case .migration:
            return CoreDataOptions.makeOptions(inferMapping: true)
        }
    }
    
    private static func makeOptions(inferMapping: Bool) -> [String: Any] {
        let sqliteOptions: [String: String] = ["journal_mode": "DELETE"]
        
        return [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: inferMapping,
            NSSQLitePragmasOption: sqliteOptions
        ]
    }
}
