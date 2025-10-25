import Foundation

/// A generic storage abstraction (e.g. Core Data).
public protocol Storage: CustomStringConvertible, Requestable, Sendable {
    /// Main/UI-facing context (usually main queue).
    var mainContext: any Context { get }
    
    /// Background save context (private queue).
    var saveContext: any Context { get }
    
    /// Fetch entities using the main context.
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T]
    
}

// MARK: - Default fetch helper

public extension Storage {
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T] {
        try mainContext.fetch(request)
    }
}
