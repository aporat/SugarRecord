@preconcurrency import CoreData
import Foundation

public class CoreDataDefaultStorage: Storage, @unchecked Sendable {
    // MARK: - Attributes
    
    internal let store: CoreDataStore
    internal var objectModel: NSManagedObjectModel!
    internal var persistentStore: NSPersistentStore!
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    internal var rootSavingContext: NSManagedObjectContext!
    
    // MARK: - Storage
    
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
    
    public static func build(
        store: CoreDataStore,
        model: CoreDataObjectModel,
        migrate: Bool = true
    ) async throws -> CoreDataDefaultStorage {
        
        // This runs your existing, blocking `init` safely on a background thread.
        // The `.value` call awaits the result and re-throws any error.
        let storage = try await Task.detached {
            try CoreDataDefaultStorage(store: store, model: model, migrate: migrate)
        }.value
        
        return storage
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
    options: [String: Any]
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
                throw CoreDataError.persistentStoreInitialization(underlying: error)
            }
        } else if let persistentStore = persistentStore {
            return persistentStore
        }
        throw CoreDataError.persistentStoreInitialization()
    }
    return try add(store, storeCoordinator, options, true)
}

internal func cleanStoreFilesAfterFailedMigration(store: CoreDataStore) throws {
    let url = store.path
    let dir = url.deletingLastPathComponent()
    let base = url.lastPathComponent
    
    let shm = dir.appendingPathComponent(base).appendingPathExtension("shm")
    let wal = dir.appendingPathComponent(base).appendingPathExtension("wal")
    
    try FileManager.default.removeItem(at: url)
    _ = try? FileManager.default.removeItem(at: shm)
    _ = try? FileManager.default.removeItem(at: wal)
}
