@preconcurrency import CoreData
import Foundation

public extension NSManagedObjectContext {
    
    // MARK: - Fetching
    
    func fetch<T: NSManagedObject>(_ request: FetchRequest<T>) throws -> [T] {
        return try performAndWait {
            let fr = try makeNSFetchRequest(request)
            return try self.fetch(fr) as? [T] ?? []
        }
    }
    
    func fetchOne<T: NSManagedObject>(_ request: FetchRequest<T>) throws -> T? {
        return try performAndWait {
            let fr = try makeNSFetchRequest(request)
            fr.fetchLimit = 1
            return try self.fetch(fr).first as? T
        }
    }
    
    func count<T: NSManagedObject>(_ request: FetchRequest<T>) -> Int {
        return performAndWait {
            do {
                let fr = try makeNSFetchRequest(request)
                return try self.count(for: fr)
            } catch {
                return 0
            }
        }
    }
    
    // MARK: - Async Fetching
    
    func fetch<T: NSManagedObject>(_ request: FetchRequest<T>) async throws -> [T] {
        try await perform {
            let fr = try self.makeNSFetchRequest(request)
            return try self.fetch(fr) as? [T] ?? []
        }
    }
    
    func fetchOne<T: NSManagedObject>(_ request: FetchRequest<T>) async throws -> T? {
        try await perform {
            let fr = try self.makeNSFetchRequest(request)
            fr.fetchLimit = 1
            return try self.fetch(fr).first as? T
        }
    }
    
    func count<T: NSManagedObject>(_ request: FetchRequest<T>) async -> Int {
        await perform {
            do {
                let fr = try self.makeNSFetchRequest(request)
                return try self.count(for: fr)
            } catch {
                return 0
            }
        }
    }
    
    // MARK: - CRUD Helpers
    
    func new<T: NSManagedObject>() throws -> T {
        guard let entityName = T.entity().name else { throw CoreDataError.invalidType }
        
        return try performAndWait {
            guard let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self) as? T else {
                throw CoreDataError.invalidType
            }
            return object
        }
    }
    
    func remove(_ object: NSManagedObject) {
        nonisolated(unsafe) let unsafeObject = object
        
        performAndWait {
            self.delete(unsafeObject)
        }
    }
    
    func remove(_ objects: [NSManagedObject]) {
        nonisolated(unsafe) let unsafeObjects = objects
        
        performAndWait {
            unsafeObjects.forEach { self.delete($0) }
        }
    }
    
    // MARK: - Querying (Dictionaries / Values)
    
    /// Fetch a list of dictionaries for specific attributes.
    func query<T: NSManagedObject>(_ request: FetchRequest<T>, attributes: [String]) throws -> [[String: Any]] {
        return try performAndWait {
            let fr = try makeNSFetchRequest(request)
            fr.resultType = .dictionaryResultType
            fr.propertiesToFetch = attributes
            
            guard let results = try self.fetch(fr) as? [[String: Any]] else { return [] }
            return results
        }
    }
    
    /// Fetch a single value (e.g. a specific ID) from the first matching object.
    func queryOne<T: NSManagedObject>(_ request: FetchRequest<T>, attribute: String) throws -> String? {
        return try performAndWait {
            let fr = try makeNSFetchRequest(request)
            fr.resultType = .dictionaryResultType
            fr.propertiesToFetch = [attribute]
            fr.fetchLimit = 1
            
            guard let results = try self.fetch(fr) as? [[String: Any]],
                  let first = results.first else { return nil }
            
            return first[attribute] as? String
        }
    }
    
    /// Fetch a unique set of values for a specific attribute (e.g. "GetAllUserIDs").
    func querySet<T: NSManagedObject>(_ request: FetchRequest<T>, attribute: String) throws -> Set<String> {
        return try performAndWait {
            let fr = try makeNSFetchRequest(request)
            fr.resultType = .dictionaryResultType
            fr.propertiesToFetch = [attribute]
            fr.returnsDistinctResults = true
            
            guard let results = try self.fetch(fr) as? [[String: Any]] else { return [] }
            
            let values = results.compactMap { $0[attribute] as? String }
            return Set(values)
        }
    }
    
    // MARK: - Async Querying
    
    func querySet<T: NSManagedObject>(_ request: FetchRequest<T>, attribute: String) async throws -> Set<String> {
        try await perform {
            let fr = try self.makeNSFetchRequest(request)
            fr.resultType = .dictionaryResultType
            fr.propertiesToFetch = [attribute]
            fr.returnsDistinctResults = true
            
            guard let results = try self.fetch(fr) as? [[String: Any]] else { return [] }
            
            let values = results.compactMap { $0[attribute] as? String }
            return Set(values)
        }
    }
    
    // MARK: - Batch Actions
    
    /// Synchronously delete objects matching the predicate directly in the persistent store.
    /// - Note: This bypasses the context memory, so in-memory objects might become stale unless refreshed.
    func batchDelete(entityName: String, predicate: NSPredicate?) throws {
        try performAndWait {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetch.predicate = predicate
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            request.resultType = .resultTypeCount
            _ = try self.execute(request)
        }
    }
    
    /// Synchronously update properties on objects matching the predicate directly in the persistent store.
    func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?) throws {
        try performAndWait {
            let request = NSBatchUpdateRequest(entityName: entityName)
            request.propertiesToUpdate = propertiesToUpdate
            request.predicate = predicate
            request.resultType = .updatedObjectsCountResultType
            _ = try self.execute(request)
        }
    }
    
    // MARK: - Async Batch Actions
    
    func batchDelete(entityName: String, predicate: NSPredicate?) async throws {
        try await perform {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetch.predicate = predicate
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            request.resultType = .resultTypeCount
            _ = try self.execute(request)
        }
    }
    
    public func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?) async throws {
        try await perform {
            let request = NSBatchUpdateRequest(entityName: entityName)
            request.propertiesToUpdate = propertiesToUpdate
            request.predicate = predicate
            request.resultType = .updatedObjectsCountResultType
            _ = try self.execute(request)
        }
    }
    
    // MARK: - Saving
    
    /// Asynchronously saves changes in the current context and recursively saves parent contexts.
    /// This ensures data flows from Main Context -> Root Context -> SQLite Disk.
    func saveToPersistentStore() async throws {
        try await perform {
            if self.hasChanges {
                try self.save()
            }
        }
        
        if let parent = self.parent {
            try await parent.saveToPersistentStore()
        }
    }
    
    // MARK: - Internal Helpers
    
    private func makeNSFetchRequest<T: NSManagedObject>(_ request: FetchRequest<T>) throws -> NSFetchRequest<NSFetchRequestResult> {
        // FIX: Use the helper 'T.entityName'
        let name = T.entityName
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fr.predicate = request.predicate
        if let sort = request.sortDescriptor {
            fr.sortDescriptors = [sort]
        }
        fr.fetchOffset = request.fetchOffset
        fr.fetchLimit = request.fetchLimit
        return fr
    }
}
