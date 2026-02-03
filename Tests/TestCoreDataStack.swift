import XCTest
import CoreData
@testable import SugarRecord

// MARK: - Mock Model
// Defined here for testing purposes
final class MockUser: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var age: Int16
}

final class TestCoreDataStack: XCTestCase {
    
    var db: SugarRecord!
    
    // MARK: - Setup & Teardown
    
    // FIX: Removed @MainActor (must match superclass signature)
    override func setUpWithError() throws {
        // 1. Create the Model Programmatically
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
        
        // 2. Initialize SugarRecord with In-Memory store
        // We use the .model case we added to Configuration.swift
        db = try SugarRecord(store: .inMemory, model: .model(model))
    }
    
    // FIX: Removed @MainActor
    override func tearDownWithError() throws {
        db = nil
    }
    
    // MARK: - Tests
    
    
    func testDelete() throws {
        // Given
        let user: MockUser = try db.mainContext.new()
        user.name = "DeleteMe"
        try db.mainContext.save()
        
        // When
        db.mainContext.remove(user)
        try db.mainContext.save()
        
        // Then
        let count = db.mainContext.count(FetchRequest<MockUser>(db.mainContext))
        XCTAssertEqual(count, 0)
    }
    
    func testAsyncBackgroundExecution() async throws {
        // 1. Create data in background
        try await db.performBackgroundTask { context in
            let user: MockUser = try context.new()
            user.name = "Background User"
            user.age = 99
            // Auto-saves on exit of this block
        }
        
        // 2. Verify it propagated to Main Context
        // SugarRecord merges changes automatically, but depending on runloop timing in XCTest,
        // we might need to wait slightly or simply fetch.
        
        let request = FetchRequest<MockUser>(db.mainContext).filtered(key: "age", equalTo: 99)
        
        // In a real app, the merge happens via NotificationCenter.
        // In XCTest, we may need to allow the runloop to turn to process the notification.
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s wait for merge
        
        let count = await db.mainContext.count(request)
        XCTAssertEqual(count, 1, "Main context should have received the background insert")
        
        let user = try? await db.mainContext.fetchOne(request)
        XCTAssertEqual(user?.name, "Background User")
    }
}
