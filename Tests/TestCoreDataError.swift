import XCTest
import CoreData
@testable import SugarRecord

final class TestCoreDataError: XCTestCase {

    func testInvalidModelDescription() {
        let model = CoreDataObjectModel.model(NSManagedObjectModel())
        let error = CoreDataError.invalidModel(model)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("invalid"))
    }

    func testPersistentStoreInitializationWithoutUnderlying() {
        let error = CoreDataError.persistentStoreInitialization(underlying: nil)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("persistent store"))
    }

    func testPersistentStoreInitializationWithUnderlying() {
        let underlying = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "disk full"])
        let error = CoreDataError.persistentStoreInitialization(underlying: underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("disk full"))
    }

    func testContextRequiredDescription() {
        let error = CoreDataError.contextRequired
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("context"))
    }

    func testInvalidTypeDescription() {
        let error = CoreDataError.invalidType
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("entity type"))
    }
}
