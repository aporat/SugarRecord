import CoreData
import Foundation

// MARK: - NSManagedObjectContext Extension (Context)

extension NSManagedObjectContext: Context {
    
    // Small helper to avoid repeating boilerplate
    private func makeRequest<T: Entity>(
        for type: T.Type,
        predicate: NSPredicate?,
        sort: NSSortDescriptor?,
        offset: Int,
        limit: Int
    ) throws -> NSFetchRequest<any NSFetchRequestResult> {
        guard let entityType = T.self as? NSManagedObject.Type else {
            throw StorageError.invalidType
        }
        let fr = NSFetchRequest<any NSFetchRequestResult>(entityName: entityType.entityName)
        fr.predicate = predicate
        fr.sortDescriptors = sort.map { [$0] }
        fr.fetchOffset = offset
        fr.fetchLimit = limit
        return fr
    }
    
    public func fetch<T: Entity>(_ request: FetchRequest<T>) throws -> [T] {
        let fr = try makeRequest(
            for: T.self,
            predicate: request.predicate,
            sort: request.sortDescriptor,
            offset: request.fetchOffset,
            limit: request.fetchLimit
        )
        let results = try fetch(fr)
        // Be defensive: avoid force-cast crash
        return results.compactMap { $0 as? T }
    }
    
    public func fetchOne<T: Entity>(_ request: FetchRequest<T>) throws -> T? {
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
    
    public func query<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) throws -> [[String: Any]] {
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
    
    public func query<T: Entity>(_ request: FetchRequest<T>, attribute: String) throws -> [String]? {
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
    
    public func querySet<T: Entity>(_ request: FetchRequest<T>, attribute: String) throws -> Set<String>? {
        let fr = try makeRequest(
            for: T.self,
            predicate: request.predicate,
            sort: request.sortDescriptor,
            offset: request.fetchOffset,
            limit: request.fetchLimit
        )
        fr.propertiesToFetch = [attribute]
        fr.resultType = .dictionaryResultType
        fr.returnsDistinctResults = true  // ensure distinctness at the SQL level when possible
        
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
    
    public func queryOne<T: Entity>(_ request: FetchRequest<T>, attributes: [String]) throws -> [String: Any]? {
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
    
    public func count<T: Entity>(_ request: FetchRequest<T>) -> Int {
        // Keep signature the same; return 0 on error as before
        guard let fr = try? makeRequest(
            for: T.self,
            predicate: request.predicate,
            sort: nil,
            offset: 0,
            limit: 0
        ) else { return 0 }
        
        return (try? self.count(for: fr)) ?? 0
    }
    
    // Insert semantics for Core Data: if object is unmanaged, insert it.
    public func insert<T: Entity>(_ object: T) throws {
        guard let mo = object as? NSManagedObject else { throw StorageError.invalidType }
        if mo.managedObjectContext == nil {
            self.insert(mo)
        }
    }
    
    public func new<T: Entity>() throws -> T {
        guard let entity = T.self as? NSManagedObject.Type else { throw StorageError.invalidType }
        let object = NSEntityDescription.insertNewObject(forEntityName: entity.entityName, into: self)
        if let inserted = object as? T {
            return inserted
        }
        throw StorageError.invalidType
    }
    
    public func remove<T: Entity>(_ objects: [T]) throws {
        for object in objects {
            if let mo = object as? NSManagedObject {
                delete(mo)
            }
        }
    }
    
    public func saveToPersistentStore(_ completion: ((Swift.Result<Any?, any Error>) -> Void)? = nil) {
        performAndWait {
            do {
                try self.save()
                if let parentContext = self.parent {
                    parentContext.saveToPersistentStore(completion)
                } else {
                    DispatchQueue.main.async { completion?(.success(nil)) }
                }
            } catch {
                DispatchQueue.main.async { completion?(.failure(error)) }
            }
        }
    }
    
    // MARK: - Batch Actions
    
    public func batchUpdate(entityName: String, propertiesToUpdate: [AnyHashable: Any]?, predicate: NSPredicate?) {
        let request = NSBatchUpdateRequest(entityName: entityName)
        request.propertiesToUpdate = propertiesToUpdate
        request.resultType = .updatedObjectsCountResultType
        request.predicate = predicate
        _ = try? execute(request)
    }
    
    public func batchDelete(entityName: String, predicate: NSPredicate?) {
        let fetch = NSFetchRequest<any NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? execute(request)
    }
}

// MARK: - NSManagedObjectContext Extension (Utils)

extension NSManagedObjectContext {
    func observe(inMainThread mainThread: Bool, saveNotification: @escaping (_ notification: Notification) -> Void) {
        let queue: OperationQueue = mainThread ? .main : OperationQueue()
        NotificationCenter.default.addObserver(
            forName: NSManagedObjectContext.didSaveObjectsNotification,
            object: self,
            queue: queue,
            using: saveNotification
        )
    }
    
    func observeToGetPermanentIDsBeforeSaving() {
        NotificationCenter.default.addObserver(
            forName: NSManagedObjectContext.willSaveObjectsNotification,
            object: self,
            queue: nil
        ) { [weak self] _ in
            guard let s = self, !s.insertedObjects.isEmpty else { return }
            _ = try? s.obtainPermanentIDs(for: Array(s.insertedObjects))
        }
    }
}
