import Foundation

/// Errors thrown by the storage layer.
@frozen
public enum StorageError: Error, Sendable {
    case writeError
    case invalidType
    case fetchError(any Error)
    case store(any Error)
    case invalidOperation(String)
    case unknown
}

// MARK: - Convenience

public extension StorageError {
    init(wrapping error: any Error) {
        if let storageError = error as? StorageError {
            self = storageError
        } else {
            self = .store(error)
        }
    }
    
    /// A lightweight policy you can refine over time.
    var isRetriable: Bool {
        switch self {
        case .writeError:           return true
        case .fetchError:           return true
        case .store:                return true
        case .invalidType:          return false
        case .invalidOperation:     return false
        case .unknown:              return true
        }
    }
}

// MARK: - Localized descriptions

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .writeError:
            return "Failed to write to the persistent store."
        case .invalidType:
            return "The value type is invalid for this operation."
        case .fetchError(let underlying):
            return "Failed to fetch from the store: \(underlying.localizedDescription)"
        case .store(let underlying):
            return "Storage layer returned an error: \(underlying.localizedDescription)"
        case .invalidOperation(let message):
            return "Invalid operation: \(message)"
        case .unknown:
            return "An unknown storage error occurred."
        }
    }
}

// MARK: - NSError bridging

extension StorageError: CustomNSError {
    public static var errorDomain: String { "com.aporat.SugarRecord.StorageError" }
    
    public var errorCode: Int {
        switch self {
        case .writeError:            return 1
        case .invalidType:           return 2
        case .fetchError:            return 3
        case .store:                 return 4
        case .invalidOperation:      return 5
        case .unknown:               return 999
        }
    }
    
    public var errorUserInfo: [String : Any] {
        var info: [String: Any] = [NSLocalizedDescriptionKey: errorDescription ?? ""]
        
        switch self {
        case .fetchError(let underlying),
                .store(let underlying):
            info[NSUnderlyingErrorKey] = underlying
        case .invalidOperation(let message):
            info["OperationMessage"] = message
        default:
            break
        }
        return info
    }
}
