import Foundation

/// A generic storage abstraction (e.g. Core Data).
public protocol Storage: CustomStringConvertible, Requestable {
    /// Main/UI-facing context (usually main queue).
    var mainContext: any Context { get }

    /// Background save context (private queue).
    var saveContext: any Context { get }

    /// Remove the underlying store files.
    func removeStore() throws

    /// Perform work on a context. Call `save()` inside to persist.
    func operation<T>(
        _ operation: @escaping (_ context: any Context, _ save: @escaping () -> Void) throws -> T
    ) throws -> T

    /// Perform background work and call completion with any error.
    func backgroundOperation(
        _ operation: @escaping (_ context: any Context, _ save: @escaping () -> Void) -> Void,
        completion: @escaping ((any Error)?) -> Void
    )

    /// Fetch entities using the main context.
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T]
}

// MARK: - Default fetch helper

public extension Storage {
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T] {
        try mainContext.fetch(request)
    }
}
