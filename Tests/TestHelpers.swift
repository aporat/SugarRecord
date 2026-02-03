import CoreData
@testable import SugarRecord

// MARK: - Mock Model

final class MockUser: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var age: Int16
}

// MARK: - Test Model Builder

enum TestModelBuilder {

    /// Creates an in-memory `NSManagedObjectModel` with a MockUser entity.
    static func makeMockModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "MockUser"
        entity.managedObjectClassName = NSStringFromClass(MockUser.self)

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false

        let ageAttr = NSAttributeDescription()
        ageAttr.name = "age"
        ageAttr.attributeType = .integer16AttributeType

        entity.properties = [nameAttr, ageAttr]
        model.entities = [entity]

        return model
    }

    /// Shared model singleton — avoids "Multiple NSEntityDescriptions claim MockUser" errors
    /// that occur when each test class creates its own NSManagedObjectModel instance.
    static let sharedModel: NSManagedObjectModel = makeMockModel()

    /// Creates a `SugarRecord` instance backed by an in-memory store using the shared model.
    static func makeInMemoryStore() throws -> SugarRecord {
        try SugarRecord(store: .inMemory, model: .model(sharedModel))
    }
}
