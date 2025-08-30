import CoreData
import Foundation

public class CoreDataDefaultStorage: Storage {
    // MARK: - Attributes
    
    internal let store: CoreDataStore
    internal var objectModel: NSManagedObjectModel!
    internal var persistentStore: NSPersistentStore!
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    internal var rootSavingContext: NSManagedObjectContext!
    
    // MARK: - Storage conformance
    
    public var description: String {
        "CoreDataDefaultStorage(\(store.path.lastPathComponent))"
    }
    
    public var mainContext: any Context
    
    public lazy var saveContext: any Context = {
        let ctx = makeContext(withParent: .parentContext(rootSavingContext),
                              concurrencyType: .privateQueueConcurrencyType)
        ctx.observe(inMainThread: true) { [weak self] notification in
            (self?.mainContext as? NSManagedObjectContext)?
                .mergeChanges(fromContextDidSave: notification as Notification)
        }
        return ctx
    }()
    
    public func operation<T>(
        _ operation: @escaping (_ context: any Context, _ save: @escaping () -> Void) throws -> T
    ) throws -> T {
        let context: NSManagedObjectContext = saveContext as! NSManagedObjectContext
        var capturedError: (any Error)?
        var returnedObject: T!
        
        context.performAndWait {
            do {
                returnedObject = try operation(context) {
                    do {
                        try context.save()
                    } catch {
                        capturedError = error
                    }
                    self.rootSavingContext.performAndWait {
                        if self.rootSavingContext.hasChanges {
                            do {
                                try self.rootSavingContext.save()
                            } catch {
                                capturedError = error
                            }
                        }
                    }
                }
            } catch {
                capturedError = error
            }
        }
        
        if let error = capturedError { throw error }
        return returnedObject
    }
    
    public func backgroundOperation(
        _ operation: @escaping (_ context: any Context, _ save: @escaping () -> Void) -> Void,
        completion: @escaping ((any Error)?) -> Void
    ) {
        let context: NSManagedObjectContext = saveContext as! NSManagedObjectContext
        var capturedError: (any Error)?
        context.perform {
            operation(context) {
                do {
                    try context.save()
                } catch {
                    capturedError = error
                }
                self.rootSavingContext.perform {
                    if self.rootSavingContext.hasChanges {
                        do {
                            try self.rootSavingContext.save()
                        } catch {
                            capturedError = error
                        }
                    }
                    completion(capturedError)
                }
            }
        }
    }
    
    public func removeStore() throws {
        let url = store.path
        let dir = url.deletingLastPathComponent()
        let base = url.lastPathComponent
        let shm = dir.appendingPathComponent(base + "-shm")
        let wal = dir.appendingPathComponent(base + "-wal")
        
        try FileManager.default.removeItem(at: url)
        _ = try? FileManager.default.removeItem(at: shm)
        _ = try? FileManager.default.removeItem(at: wal)
    }
    
    // MARK: - Init
    
    public init(store: CoreDataStore, model: CoreDataObjectModel, migrate: Bool = true) throws {
        self.store = store
        guard let om = model.load() else {
            throw CoreDataError.invalidModel(model)
        }
        objectModel = om
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        persistentStore = try initializeStore(store: store,
                                              storeCoordinator: persistentStoreCoordinator,
                                              migrate: migrate)
        rootSavingContext = makeContext(withParent: .storeCoordinator(persistentStoreCoordinator),
                                        concurrencyType: .privateQueueConcurrencyType)
        mainContext = makeContext(withParent: .parentContext(rootSavingContext),
                                  concurrencyType: .mainQueueConcurrencyType)
    }
}

// MARK: - Internal helpers

internal func makeContext(
    withParent parent: CoreDataContextParent?,
    concurrencyType: NSManagedObjectContextConcurrencyType
) -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: concurrencyType)
    if let parent = parent {
        switch parent {
        case let .parentContext(parentContext):
            context.parent = parentContext
        case let .storeCoordinator(storeCoordinator):
            context.persistentStoreCoordinator = storeCoordinator
        }
    }
    context.observeToGetPermanentIDsBeforeSaving()
    return context
}

internal func initializeStore(
    store: CoreDataStore,
    storeCoordinator: NSPersistentStoreCoordinator,
    migrate: Bool
) throws -> NSPersistentStore {
    try createStoreParentPathIfNeeded(store: store)
    let options = migrate ? CoreDataOptions.migration : CoreDataOptions.basic
    return try addPersistentStore(store: store,
                                  storeCoordinator: storeCoordinator,
                                  options: options.settings)
}

internal func createStoreParentPathIfNeeded(store: CoreDataStore) throws {
    let databaseParentPath = store.path.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: databaseParentPath,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
}

internal func addPersistentStore(
    store: CoreDataStore,
    storeCoordinator: NSPersistentStoreCoordinator,
    options: [String: Any]   // <- changed to Any to match CoreDataOptions.settings
) throws -> NSPersistentStore {
    func add(
        _ store: CoreDataStore,
        _ storeCoordinator: NSPersistentStoreCoordinator,
        _ options: [String: Any],
        _ cleanAndRetryIfMigrationFails: Bool
    ) throws -> NSPersistentStore {
        var persistentStore: NSPersistentStore?
        var error: NSError?
        storeCoordinator.performAndWait {
            do {
                persistentStore = try storeCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: store.path,
                    options: options
                )
            } catch let _error as NSError {
                error = _error
            }
        }
        if let error = error {
            let isMigrationError =
                error.code == NSPersistentStoreIncompatibleVersionHashError ||
                error.code == NSMigrationMissingSourceModelError
            if isMigrationError && cleanAndRetryIfMigrationFails {
                _ = try? cleanStoreFilesAfterFailedMigration(store: store)
                return try add(store, storeCoordinator, options, false)
            } else {
                // wrap the underlying error in your CoreDataError case
                throw CoreDataError.persistentStoreInitialization(underlying: error)
            }
        } else if let persistentStore = persistentStore {
            return persistentStore
        }
        // no error captured but store not created: generic initialization failure
        throw CoreDataError.persistentStoreInitialization()
    }
    return try add(store, storeCoordinator, options, true)
}

internal func cleanStoreFilesAfterFailedMigration(store: CoreDataStore) throws {
    let url = store.path
    let dir = url.deletingLastPathComponent()
    let base = url.lastPathComponent
    let shm = dir.appendingPathComponent(base + "-shm")
    let wal = dir.appendingPathComponent(base + "-wal")
    
    try FileManager.default.removeItem(at: url)
    _ = try? FileManager.default.removeItem(at: shm)
    _ = try? FileManager.default.removeItem(at: wal)
}
