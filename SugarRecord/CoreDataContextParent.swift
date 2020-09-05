import CoreData
import Foundation

enum CoreDataContextParent {
    case coordinator(NSPersistentStoreCoordinator)
    case context(NSManagedObjectContext)
}
