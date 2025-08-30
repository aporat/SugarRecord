import CoreData
import Foundation

// MARK: - Entity name

extension NSManagedObject {
    /// The Core Data entity name for this managed object class.
    /// Defaults to the class name (without module prefix) and strips a trailing "Entity" if present.
    public class var entityName: String {
        let full = NSStringFromClass(self)                 // e.g. "MyApp.NoteEntity"
        let bare = full.components(separatedBy: ".").last  ?? full
        if bare.hasSuffix("Entity") {
            return String(bare.dropLast("Entity".count))
        }
        return bare
    }
}

// MARK: - NSManagedObject conforms to your Entity marker

extension NSManagedObject: Entity {}

// MARK: - Convenience request builder

extension NSManagedObject {
    /// Build a typed `FetchRequest<T>` from any `Requestable` (e.g. a `Context` or `Storage`).
    public static func request<T: Entity>(requestable: any Requestable) -> FetchRequest<T> {
        FetchRequest(requestable)
    }
}
