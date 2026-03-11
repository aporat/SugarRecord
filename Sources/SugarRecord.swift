@preconcurrency import CoreData
import Foundation

/// The Main Manager for the Core Data Stack, backed by NSPersistentContainer.
public class SugarRecord: @unchecked Sendable {
    
    // MARK: - Attributes
    
    public let store: CoreDataStore
    public let name: String
    
    internal let container: NSPersistentContainer
    
    // MARK: - Contexts
    
    /// Main/UI-facing context (Main Actor).
    public var mainContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Init
    
    public init(store: CoreDataStore, model: CoreDataObjectModel, migrate: Bool = true) throws {
        self.store = store
        
        guard let om = model.load() else {
            throw CoreDataError.invalidModel(model)
        }
        
        self.name = store.path?.lastPathComponent ?? "InMemoryStore"
        self.container = NSPersistentContainer(name: self.name, managedObjectModel: om)
        
        // Configure store description
        let description = NSPersistentStoreDescription()
        
        switch store {
        case .inMemory:
            description.type = NSInMemoryStoreType
        case .named, .url:
            if let url = store.path {
                let parentDir = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
                description.url = url
            }
            description.type = NSSQLiteStoreType
            description.setOption(["journal_mode": "DELETE"] as NSDictionary, forKey: NSSQLitePragmasOption)
        }
        
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = migrate
        
        container.persistentStoreDescriptions = [description]
        
        // Load stores synchronously
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let error = loadError {
            throw CoreDataError.persistentStoreInitialization(underlying: error)
        }
        
        // Configure the view context
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
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
        try await container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            try block(context)
            if context.hasChanges {
                try context.save()
            }
        }
    }
}
