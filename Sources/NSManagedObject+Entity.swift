@preconcurrency import CoreData
import Foundation

// MARK: - Entity name

extension NSManagedObject {
    /// Reliable way to get the entity name from the class type.
    /// Falls back to the class name (stripping module prefix).
    static var entityName: String {
        if let name = entity().name {
            return name
        }
        
        let fullClassName = NSStringFromClass(self)
        let name = fullClassName.components(separatedBy: ".").last ?? fullClassName
        return name
    }
}
