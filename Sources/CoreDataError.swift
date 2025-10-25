@preconcurrency import CoreData
import Foundation

@frozen public enum CoreDataError: Error, Sendable {
    case invalidModel(CoreDataObjectModel)
    
    case persistentStoreInitialization(underlying: (any Error)? = nil)
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
        }
    }
}

// MARK: - NSError bridging

extension CoreDataError: CustomNSError {
    public static var errorDomain: String { "com.aporat.SugarRecord.CoreDataError" }
    
    public var errorCode: Int {
        switch self {
        case .invalidModel:                  return 1
        case .persistentStoreInitialization: return 2
        }
    }
    
    public var errorUserInfo: [String : Any] {
        var info: [String: Any] = [NSLocalizedDescriptionKey: errorDescription ?? ""]
        if case .persistentStoreInitialization(let underlying?) = self {
            info[NSUnderlyingErrorKey] = underlying
        }
        return info
    }
}
