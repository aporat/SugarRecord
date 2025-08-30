import XCTest
import CoreData
@testable import SugarRecord

@objc(NoteEntity)
final class NoteEntity: NSManagedObject {}

extension NoteEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }
    @NSManaged var title: String?
    @NSManaged var userId: String?
    @NSManaged var createdAt: Date?
}

final class TestCoreDataStack {
    let model: NSManagedObjectModel
    let coordinator: NSPersistentStoreCoordinator
    let rootContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext

    init() {
        // Build model programmatically so we don't need a .momd file.
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "NoteEntity"
        entity.managedObjectClassName = NSStringFromClass(NoteEntity.self)

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = true

        let userId = NSAttributeDescription()
        userId.name = "userId"
        userId.attributeType = .stringAttributeType
        userId.isOptional = true

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = true

        entity.properties = [title, userId, createdAt]
        model.entities = [entity]
        self.model = model

        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        self.coordinator = psc

        // In-memory store for fast isolated tests.
        try! psc.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

        // Root private context (saves to store)
        let root = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        root.persistentStoreCoordinator = psc
        self.rootContext = root

        // Main context (child of root)
        let main = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        main.parent = root
        self.mainContext = main
    }

    func makeNote(title: String, userId: String, createdAt: Date = .init()) -> NoteEntity {
        let note = NSEntityDescription.insertNewObject(forEntityName: "NoteEntity", into: mainContext) as! NoteEntity
        note.title = title
        note.userId = userId
        note.createdAt = createdAt
        return note
    }

    func save() throws {
        if mainContext.hasChanges {
            try mainContext.save()
        }
        var err: Error?
        rootContext.performAndWait {
            do { if self.rootContext.hasChanges { try self.rootContext.save() } }
            catch { err = error }
        }
        if let e = err { throw e }
    }
}
