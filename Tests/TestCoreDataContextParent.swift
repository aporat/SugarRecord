import XCTest
import CoreData
@testable import SugarRecord

final class TestCoreDataContextParent: XCTestCase {

    // MARK: - Description

    func testStoreCoordinatorDescription() {
        let model = NSManagedObjectModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let parent = CoreDataContextParent.storeCoordinator(coordinator)
        XCTAssertEqual(parent.description, "CoreDataContextParent.storeCoordinator")
    }

    func testParentContextDescription() {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let parent = CoreDataContextParent.parentContext(context)
        XCTAssertEqual(parent.description, "CoreDataContextParent.parentContext")
    }

    // MARK: - Equatable

    func testSameCoordinatorIsEqual() {
        let model = NSManagedObjectModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let a = CoreDataContextParent.storeCoordinator(coordinator)
        let b = CoreDataContextParent.storeCoordinator(coordinator)
        XCTAssertEqual(a, b)
    }

    func testDifferentCoordinatorsAreNotEqual() {
        let model = NSManagedObjectModel()
        let c1 = NSPersistentStoreCoordinator(managedObjectModel: model)
        let c2 = NSPersistentStoreCoordinator(managedObjectModel: model)
        XCTAssertNotEqual(
            CoreDataContextParent.storeCoordinator(c1),
            CoreDataContextParent.storeCoordinator(c2)
        )
    }

    func testSameContextIsEqual() {
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        XCTAssertEqual(
            CoreDataContextParent.parentContext(ctx),
            CoreDataContextParent.parentContext(ctx)
        )
    }

    func testDifferentContextsAreNotEqual() {
        let ctx1 = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let ctx2 = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        XCTAssertNotEqual(
            CoreDataContextParent.parentContext(ctx1),
            CoreDataContextParent.parentContext(ctx2)
        )
    }

    func testDifferentCasesAreNotEqual() {
        let model = NSManagedObjectModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        XCTAssertNotEqual(
            CoreDataContextParent.storeCoordinator(coordinator),
            CoreDataContextParent.parentContext(context)
        )
    }

    // MARK: - Hashable

    func testHashableInSet() {
        let model = NSManagedObjectModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        let set: Set<CoreDataContextParent> = [
            .storeCoordinator(coordinator),
            .storeCoordinator(coordinator),
            .parentContext(context)
        ]
        XCTAssertEqual(set.count, 2)
    }
}
