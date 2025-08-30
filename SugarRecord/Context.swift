import Foundation

public protocol Context: Requestable {
    // Fetching
    func fetch<T>(_ request: FetchRequest<T>) throws -> [T] where T: Entity
    func fetchOne<T>(_ request: FetchRequest<T>) throws -> T? where T: Entity

    // Creation / insertion
    func insert<T>(_ entity: T) throws where T: Entity
    func new<T>() throws -> T where T: Entity
    func create<T>() throws -> T where T: Entity

    // Querying
    func query<T>(_ request: FetchRequest<T>, attributes: [String]) throws -> [[String: Any]] where T: Entity
    func query<T>(_ request: FetchRequest<T>, attribute: String) throws -> [String]? where T: Entity
    func querySet<T>(_ request: FetchRequest<T>, attribute: String) throws -> Set<String>? where T: Entity
    func queryOne<T>(_ request: FetchRequest<T>, attributes: [String]) throws -> [String: Any]? where T: Entity
    func count<T>(_ request: FetchRequest<T>) -> Int where T: Entity

    // Deletion
    func remove<T>(_ objects: [T]) throws where T: Entity
    func remove<T>(_ object: T) throws where T: Entity

    // Saving
    func saveToPersistentStore(_ completion: ((Swift.Result<Any?, any Error>) -> Void)?)

    // Batch actions
    func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?)
    func batchDelete(entityName: String, predicate: NSPredicate?)
}

// MARK: - Default conveniences

public extension Context {
    func create<T>() throws -> T where T: Entity {
        let instance: T = try new()
        try insert(instance)
        return instance
    }

    func remove<T>(_ object: T) throws where T: Entity {
        try remove([object])
    }
}
