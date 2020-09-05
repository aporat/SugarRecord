import Foundation

public protocol Storage: CustomStringConvertible, Requestable {
    var mainContext: Context! { get }
    var saveContext: Context! { get }
    func removeStore() throws
    func operation<T>(_ operation: @escaping (_ context: Context, _ save: @escaping () -> Void) throws -> T) throws -> T
    func backgroundOperation(_ operation: @escaping (_ context: Context, _ save: @escaping () -> Void) -> Void, completion: @escaping (Error?) -> Void)
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T]
}

// MARK: - Storage extension (Fetching)

public extension Storage {
    func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T] {
        try mainContext.fetch(request)
    }
}
