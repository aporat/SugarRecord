@preconcurrency import CoreData
import Foundation

/// The Main Manager for the Core Data Stack.
public class SugarRecord: @unchecked Sendable {
    
    // MARK: - Attributes
    public let store: CoreDataStore!
    public let name: String
    
    internal var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    internal var rootSavingContext: NSManagedObjectContext!
    
    // MARK: - Contexts
    
    /// Main/UI-facing context (Main Actor).
    public var mainContext: NSManagedObjectContext!
    
    
    // MARK: - Init
    
    public init(store: CoreDataStore, model: CoreDataObjectModel, migrate: Bool = true) throws {
        self.store = store
        self.name = store.path?.lastPathComponent ?? "InMemoryStore"
        
        guard let om = model.load() else {
            throw CoreDataError.invalidModel(model)
        }
        
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: om)
        
        // Initialize Store
        try Self.createStoreParentPathIfNeeded(store: store)
        let options = migrate ? CoreDataOptions.migration : CoreDataOptions.basic
        try Self.addPersistentStore(store: store, coordinator: persistentStoreCoordinator, options: options.settings)
        
        // Root Saving Context (Private Queue, connected to Store)
        self.rootSavingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.rootSavingContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        self.rootSavingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Main Context (Main Queue, child of Root)
        self.mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.mainContext.parent = self.rootSavingContext
        self.mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.mainContext.observeToGetPermanentIDsBeforeSaving()
    }
    
    /// Async Builder
    public static func build(store: CoreDataStore, model: CoreDataObjectModel, migrate: Bool = true) async throws -> SugarRecord {
        try await Task.detached {
            try SugarRecord(store: store, model: model, migrate: migrate)
        }.value
    }
    
    // MARK: - Background Execution
    
    /// Perform a background task safely on a private queue context.
    /// The closure is synchronous to ensure Core Data thread confinement safety.
    public func performBackgroundTask(_ block: @Sendable @escaping (NSManagedObjectContext) throws -> Void) async throws {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        backgroundContext.observeContextOnSave(inMainThread: true) { [weak self] notification in
            self?.mainContext.mergeChanges(fromContextDidSave: notification)
        }
        
        try await backgroundContext.perform {
            try block(backgroundContext)
            
            if backgroundContext.hasChanges {
                try backgroundContext.save()
            }
        }
    }
    
    // MARK: - Internal Helpers
    
    private static func createStoreParentPathIfNeeded(store: CoreDataStore) throws {
        guard let url = store.path else { return }
        
        let databaseParentPath = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: databaseParentPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    private static func addPersistentStore(store: CoreDataStore, coordinator: NSPersistentStoreCoordinator, options: [String: Any]) throws {
        do {
            switch store {
            case .inMemory:
                try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: options)
            default:
                guard let url = store.path else { throw CoreDataError.persistentStoreInitialization(underlying: nil) }
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            }
        } catch {
            throw CoreDataError.persistentStoreInitialization(underlying: error)
        }
    }
}

// MARK: - Notification Helper

extension NSManagedObjectContext {
    func observeContextOnSave(inMainThread: Bool, _ block: @escaping @Sendable (Notification) -> Void) {
        let queue: OperationQueue = inMainThread ? .main : OperationQueue()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: self, queue: queue, using: block)
    }
    
    func observeToGetPermanentIDsBeforeSaving() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextWillSave, object: self, queue: nil) { [weak self] _ in
            guard let self else { return }
            self.performAndWait {
                if !self.insertedObjects.isEmpty {
                    _ = try? self.obtainPermanentIDs(for: Array(self.insertedObjects))
                }
            }
        }
    }
}
