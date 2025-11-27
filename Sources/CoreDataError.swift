@preconcurrency import CoreData
import Foundation

@frozen public enum CoreDataError: Error, Sendable {
    case invalidModel(CoreDataObjectModel)
    
    case persistentStoreInitialization(underlying: (any Error)? = nil)
    
    case contextRequired
        case invalidType
}

// MARK: - LocalizedError

extension CoreDataError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidModel(let model):
            return "The Core Data model is invalid: \(model)."
        case .persistentStoreInitialization(let underlying):
            if let e = underlying {
                return "Failed to initialize the persistent store: \(e.localizedDescription)"
            }
            return "Failed to initialize the persistent store."
        case .contextRequired:
            return "The operation cannot be performed because the context is nil."
        case .invalidType:
            return "The entity type is invalid or could not be cast correctly."
        }
    }
}
