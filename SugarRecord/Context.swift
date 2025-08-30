import Foundation

public protocol Context: Requestable {
    // Fetching
    func fetchAll<T: Entity>(_ request: FetchRequest<T>) throws -> [T]
    func fetchFirst<T: Entity>(_ request: FetchRequest<T>) throws -> T?

    // Creation / insertion
    func insertEntity<T: Entity>(_ entity: T) throws
    func makeNewEntity<T: Entity>() throws -> T
    func createAndInsertEntity<T: Entity>() throws -> T

    // Querying
    func queryAttributes<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) throws -> [[String: Any]]
    func queryAttributeValues<T: Entity>(_ request: FetchRequest<T>, attribute: String) throws -> [String]?
    func queryDistinctAttributeValues<T: Entity>(_ request: FetchRequest<T>, attribute: String) throws -> Set<String>?
    func queryFirstAttributes<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) throws -> [String: Any]?
    func countEntities<T: Entity>(_ request: FetchRequest<T>) -> Int

    // Deletion
    func deleteEntities<T: Entity>(_ objects: [T]) throws
    func deleteEntity<T: Entity>(_ object: T) throws

    // Saving
    func saveToPersistentStore(_ completion: ((Swift.Result<Any?, any Error>) -> Void)?)

    // Batch actions
    func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?)
    func batchDelete(entityName: String, predicate: NSPredicate?)
}

// MARK: - Default conveniences

public extension Context {
    func createAndInsertEntity<T: Entity>() throws -> T {
        let instance: T = try makeNewEntity()
        try insertEntity(instance)
        return instance
    }

    func deleteEntity<T: Entity>(_ object: T) throws {
        try deleteEntities([object])
    }
}
