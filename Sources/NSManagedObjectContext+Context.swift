@preconcurrency import CoreData
import Foundation

public typealias AnyFetchRequest = NSFetchRequest<any NSFetchRequestResult>

// MARK: - NSManagedObjectContext Extension (Context)

extension NSManagedObjectContext: Context {
    
    private func makeRequest<T: Entity>(
        for type: T.Type,
        predicate: NSPredicate?,
        sort: NSSortDescriptor?,
        offset: Int,
        limit: Int
    ) throws -> AnyFetchRequest {
        guard let entityType = T.self as? NSManagedObject.Type else {
            throw StorageError.invalidType
        }
        let fr = AnyFetchRequest(entityName: entityType.entityName)
        fr.predicate = predicate
        fr.sortDescriptors = sort.map { [$0] }
        fr.fetchOffset = offset
        fr.fetchLimit = limit
        return fr
    }
    
    // MARK: Fetching
    public func fetch<T: Entity>(_ request: FetchRequest<T>) async throws -> [T] {
        try await perform {
            let fr = try self.makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            let results = try self.fetch(fr)
            return results.compactMap { $0 as? T }
        }
    }
    
    public func fetchOne<T: Entity>(_ request: FetchRequest<T>) async throws -> T? {
        try await perform {
            let fr = try self.makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: 1 // Only fetch one
            )
            let results = try self.fetch(fr)
            return results.first as? T
        }
    }
    
    public func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T] {
        try performAndWait {
            let fr = try makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            let results = try fetch(fr)
            return results.compactMap { $0 as? T }
        }
    }
    
    public func fetchOne<T: Entity>(_ request: FetchRequest<T>) throws -> T? {
        try performAndWait {
            let fr = try makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: 1
            )
            let results = try fetch(fr)
            return results.first as? T
        }
    }
    
    // MARK: Creation / insertion
    
    public func insert<T: Entity>(_ entity: T) throws {
        try performAndWait {
            guard let mo = entity as? NSManagedObject else { throw StorageError.invalidType }
            if mo.managedObjectContext == nil {
                self.insert(mo)
            }
        }
    }
    
    public func new<T: Entity>() throws -> T {
        try performAndWait {
            guard let type = T.self as? NSManagedObject.Type else { throw StorageError.invalidType }
            let obj = NSEntityDescription.insertNewObject(forEntityName: type.entityName, into: self)
            guard let typed = obj as? T else { throw StorageError.invalidType }
            return typed
        }
    }
    
    public func insert<T: Entity>(_ entity: T) async throws {
        try await perform {
            guard let mo = entity as? NSManagedObject else { throw StorageError.invalidType }
            if mo.managedObjectContext == nil {
                self.insert(mo)
            }
        }
    }
    
    public func new<T: Entity>() async throws -> T {
        try await perform {
            guard let type = T.self as? NSManagedObject.Type else { throw StorageError.invalidType }
            let obj = NSEntityDescription.insertNewObject(forEntityName: type.entityName, into: self)
            guard let typed = obj as? T else { throw StorageError.invalidType }
            return typed
        }
    }
    
    // MARK: Querying
    
    public func query<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) throws -> [[String: Any]] {
        try performAndWait {
            let fr = try makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            fr.propertiesToFetch = attributes
            fr.resultType = .dictionaryResultType
            
            let results = try fetch(fr)
            return results.compactMap { $0 as? [String: Any] }
        }
    }
    
    public func query<T: Entity>(_ request: FetchRequest<T>, attribute: String) throws -> [String]? {
        try performAndWait {
            let fr = try makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            fr.propertiesToFetch = [attribute]
            fr.resultType = .dictionaryResultType
            
            let results = try fetch(fr)
            var elements: [String] = []
            results.compactMap { $0 as? [String: Any] }.forEach {
                if let value = $0[attribute] as? String {
                    elements.append(value)
                }
            }
            return elements
        }
    }
    
    public func querySet<T: Entity>(_ request: FetchRequest<T>, attribute: String) throws -> Set<String>? {
        try performAndWait {
            let fr = try makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            fr.propertiesToFetch = [attribute]
            fr.resultType = .dictionaryResultType
            fr.returnsDistinctResults = true
            fr.propertiesToGroupBy = [attribute] // improves correctness on SQLite
            
            let results = try fetch(fr)
            var ids = Set<String>()
            if let dicts = results as? [[String: Any]] {
                for item in dicts {
                    if let id = item[attribute] as? String {
                        ids.insert(id)
                    }
                }
            }
            return ids
        }
    }
    
    public func queryOne<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) throws -> [String: Any]? {
        try performAndWait {
            let fr = try makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: 1
            )
            fr.propertiesToFetch = attributes
            fr.resultType = .dictionaryResultType
            
            let results = try fetch(fr)
            return results.compactMap { $0 as? [String: Any] }.first
        }
    }
    
    public func count<T: Entity>(_ request: FetchRequest<T>) -> Int {
        performAndWait {
            do {
                let fr = try makeRequest(
                    for: T.self,
                    predicate: request.predicate,
                    sort: nil,
                    offset: 0,
                    limit: 0
                )
                return try self.count(for: fr)
            } catch {
                return 0
            }
        }
    }
    
    
    public func query<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) async throws -> [[String: Any]] {
        try await perform {
            let fr = try self.makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            fr.propertiesToFetch = attributes
            fr.resultType = .dictionaryResultType
            
            let results = try self.fetch(fr)
            return results.compactMap { $0 as? [String: Any] }
        }
    }
    
    public func query<T: Entity>(_ request: FetchRequest<T>, attribute: String) async throws -> [String]? {
        try await perform {
            let fr = try self.makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            fr.propertiesToFetch = [attribute]
            fr.resultType = .dictionaryResultType
            
            let results = try self.fetch(fr)
            var elements: [String] = []
            results.compactMap { $0 as? [String: Any] }.forEach {
                if let value = $0[attribute] as? String {
                    elements.append(value)
                }
            }
            return elements
        }
    }
    
    public func querySet<T: Entity>(_ request: FetchRequest<T>, attribute: String) async throws -> Set<String>? {
        try await perform {
            let fr = try self.makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: request.fetchLimit
            )
            fr.propertiesToFetch = [attribute]
            fr.resultType = .dictionaryResultType
            fr.returnsDistinctResults = true
            fr.propertiesToGroupBy = [attribute] // improves correctness on SQLite
            
            let results = try self.fetch(fr)
            var ids = Set<String>()
            if let dicts = results as? [[String: Any]] {
                for item in dicts {
                    if let id = item[attribute] as? String {
                        ids.insert(id)
                    }
                }
            }
            return ids
        }
    }
    
    public func queryOne<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) async throws -> [String: Any]? {
        try await perform {
            let fr = try self.makeRequest(
                for: T.self,
                predicate: request.predicate,
                sort: request.sortDescriptor,
                offset: request.fetchOffset,
                limit: 1
            )
            fr.propertiesToFetch = attributes
            fr.resultType = .dictionaryResultType
            
            let results = try self.fetch(fr)
            return results.compactMap { $0 as? [String: Any] }.first
        }
    }
    
    public func count<T: Entity>(_ request: FetchRequest<T>) async -> Int {
        await perform {
            do {
                let fr = try self.makeRequest(
                    for: T.self,
                    predicate: request.predicate,
                    sort: nil,
                    offset: 0,
                    limit: 0
                )
                return try self.count(for: fr)
            } catch {
                return 0
            }
        }
    }
    
    // MARK: Deletion
    
    public func remove<T: Entity>(_ objects: [T]) throws {
        performAndWait {
            for object in objects {
                if let mo = object as? NSManagedObject {
                    delete(mo)
                }
            }
        }
    }
    
    // MARK: Saving
    
    /// Asynchronously saves changes in the current context and recursively saves parent contexts.
    /// This function performs the save on the context's queue and propagates errors.
    public func saveToPersistentStore() async throws {
        try await perform {
            if self.hasChanges {
                try self.save()
            }
        }
        
        if let parent = self.parent {
            try await parent.saveToPersistentStore()
        }
    }
    
    
    // MARK: - Batch Actions
    
    // CHANGE: Made throwing and thread-safe.
    public func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?) throws {
        try performAndWait {
            let request = NSBatchUpdateRequest(entityName: entityName)
            request.propertiesToUpdate = propertiesToUpdate
            request.resultType = .updatedObjectsCountResultType
            request.predicate = predicate
            _ = try execute(request) // No longer swallows error
        }
    }
    
    public func batchDelete(entityName: String, predicate: NSPredicate?) throws {
        try performAndWait {
            let fetch = AnyFetchRequest(entityName: entityName)
            fetch.predicate = predicate
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try execute(request) // No longer swallows error
        }
    }
    
    public func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?) async throws {
        try await perform {
            let request = NSBatchUpdateRequest(entityName: entityName)
            request.propertiesToUpdate = propertiesToUpdate
            request.resultType = .updatedObjectsCountResultType
            request.predicate = predicate
            _ = try self.execute(request)
        }
    }
    
    public func batchDelete(entityName: String, predicate: NSPredicate?) async throws {
        try await perform {
            let fetch = AnyFetchRequest(entityName: entityName)
            fetch.predicate = predicate
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try self.execute(request)
        }
    }
}

// MARK: - NSManagedObjectContext Extension (Utils)

extension NSManagedObjectContext {
    func observe(inMainThread mainThread: Bool, saveNotification: @escaping (_ notification: Notification) -> Void) {
        let queue: OperationQueue = mainThread ? .main : OperationQueue()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSManagedObjectContextDidSave,
            object: self,
            queue: queue,
            using: saveNotification
        )
    }
    
    func observeToGetPermanentIDsBeforeSaving() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSManagedObjectContextWillSave,
            object: self,
            queue: nil
        ) { [weak self] _ in
            guard let s = self else { return }
            
            // CHANGE: Wrap in `performAndWait` for thread-safety.
            s.performAndWait {
                if !s.insertedObjects.isEmpty {
                    _ = try? s.obtainPermanentIDs(for: Array(s.insertedObjects))
                }
            }
        }
    }
}
