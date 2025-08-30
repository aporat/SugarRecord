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
        "CoreDataDefaultStorage"
    }

    public var mainContext: any Context

    public lazy var saveContext: any Context = {
        let ctx = cdContext(withParent: .context(rootSavingContext),
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
        var _error: (any Error)!
        var returnedObject: T!

        context.performAndWait {
            do {
                returnedObject = try operation(context) {
                    do {
                        try context.save()
                    } catch {
                        _error = error
                    }
                    self.rootSavingContext.performAndWait {
                        if self.rootSavingContext.hasChanges {
                            do {
                                try self.rootSavingContext.save()
                            } catch {
                                _error = error
                            }
                        }
                    }
                }
            } catch {
                _error = error
            }
        }

        if let error = _error { throw error }
        return returnedObject
    }

    public func backgroundOperation(
        _ operation: @escaping (_ context: any Context, _ save: @escaping () -> Void) -> Void,
        completion: @escaping ((any Error)?) -> Void
    ) {
        let context: NSManagedObjectContext = saveContext as! NSManagedObjectContext
        var _error: (any Error)!
        context.perform {
            operation(context) {
                do {
                    try context.save()
                } catch {
                    _error = error
                }
                self.rootSavingContext.perform {
                    if self.rootSavingContext.hasChanges {
                        do {
                            try self.rootSavingContext.save()
                        } catch {
                            _error = error
                        }
                    }
                    completion(_error)
                }
            }
        }
    }

    public func removeStore() throws {
        let url = store.path()
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
        objectModel = model.model()!
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        persistentStore = try cdInitializeStore(store: store,
                                                storeCoordinator: persistentStoreCoordinator,
                                                migrate: migrate)
        rootSavingContext = cdContext(withParent: .coordinator(persistentStoreCoordinator),
                                      concurrencyType: .privateQueueConcurrencyType)
        mainContext = cdContext(withParent: .context(rootSavingContext),
                                concurrencyType: .mainQueueConcurrencyType)
    }
}

// MARK: - Internal

internal func cdContext(
    withParent parent: CoreDataContextParent?,
    concurrencyType: NSManagedObjectContextConcurrencyType
) -> NSManagedObjectContext {
    var context: NSManagedObjectContext?

    context = NSManagedObjectContext(concurrencyType: concurrencyType)

    if let parent = parent {
        switch parent {
        case let .context(parentContext):
            context!.parent = parentContext
        case let .coordinator(storeCoordinator):
            context!.persistentStoreCoordinator = storeCoordinator
        }
    }
    context!.observeToGetPermanentIDsBeforeSaving()
    return context!
}

internal func cdInitializeStore(
    store: CoreDataStore,
    storeCoordinator: NSPersistentStoreCoordinator,
    migrate: Bool
) throws -> NSPersistentStore {
    try cdCreateStoreParentPathIfNeeded(store: store)
    let options = migrate ? CoreDataOptions.migration : CoreDataOptions.basic
    return try cdAddPersistentStore(store: store,
                                    storeCoordinator: storeCoordinator,
                                    options: options.settings)
}

internal func cdCreateStoreParentPathIfNeeded(store: CoreDataStore) throws {
    let databaseParentPath = store.path().deletingLastPathComponent()
    try FileManager.default.createDirectory(at: databaseParentPath,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
}

internal func cdAddPersistentStore(
    store: CoreDataStore,
    storeCoordinator: NSPersistentStoreCoordinator,
    options: [String: AnyObject]
) throws -> NSPersistentStore {
    func addStore(
        _ store: CoreDataStore,
        _ storeCoordinator: NSPersistentStoreCoordinator,
        _ options: [String: AnyObject],
        _ cleanAndRetryIfMigrationFails: Bool
    ) throws -> NSPersistentStore {
        var persistentStore: NSPersistentStore?
        var error: NSError?
        storeCoordinator.performAndWait {
            do {
                persistentStore = try storeCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: store.path() as URL,
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
                _ = try? cdCleanStoreFilesAfterFailedMigration(store: store)
                return try addStore(store, storeCoordinator, options, false)
            } else {
                throw error
            }
        } else if let persistentStore = persistentStore {
            return persistentStore
        }
        // ⬇️ updated to the correctly spelled case
        throw CoreDataError.persistentStoreInitialization()
    }
    return try addStore(store, storeCoordinator, options, true)
}

internal func cdCleanStoreFilesAfterFailedMigration(store: CoreDataStore) throws {
    let url = store.path()
    let dir = url.deletingLastPathComponent()
    let base = url.lastPathComponent
    let shm = dir.appendingPathComponent(base + "-shm")
    let wal = dir.appendingPathComponent(base + "-wal")

    try FileManager.default.removeItem(at: url)
    _ = try? FileManager.default.removeItem(at: shm)
    _ = try? FileManager.default.removeItem(at: wal)
}
