import XCTest
import CoreData
@testable import SugarRecord

final class TestCoreDataObjectModel: XCTestCase {

    // MARK: - load()

    func testModelCaseReturnsModel() {
        let model = NSManagedObjectModel()
        let objectModel = CoreDataObjectModel.model(model)
        XCTAssertEqual(objectModel.load(), model)
    }

    func testNamedCaseWithInvalidNameReturnsNil() {
        let objectModel = CoreDataObjectModel.named("NonExistentModel", Bundle.main)
        XCTAssertNil(objectModel.load())
    }

    func testURLCaseWithInvalidURLReturnsNil() {
        let url = URL(fileURLWithPath: "/nonexistent/path.momd")
        let objectModel = CoreDataObjectModel.url(url)
        XCTAssertNil(objectModel.load())
    }

    // MARK: - Description

    func testModelDescription() {
        let model = NSManagedObjectModel()
        let objectModel = CoreDataObjectModel.model(model)
        XCTAssertTrue(objectModel.description.contains("NSManagedObjectModel"))
    }

    func testNamedDescription() {
        let objectModel = CoreDataObjectModel.named("MyModel", Bundle.main)
        let desc = objectModel.description
        XCTAssertTrue(desc.contains("MyModel"))
        XCTAssertTrue(desc.contains("named"))
    }

    func testURLDescription() {
        let url = URL(fileURLWithPath: "/tmp/model.momd")
        let objectModel = CoreDataObjectModel.url(url)
        XCTAssertTrue(objectModel.description.contains("/tmp/model.momd"))
    }

    func testMergedDescription() {
        let objectModel = CoreDataObjectModel.merged(nil)
        XCTAssertTrue(objectModel.description.contains("merged"))
    }

    // MARK: - Equatable

    func testSameModelInstancesAreEqual() {
        let model = NSManagedObjectModel()
        let a = CoreDataObjectModel.model(model)
        let b = CoreDataObjectModel.model(model)
        XCTAssertEqual(a, b)
    }

    // MARK: - Hashable

    func testHashableInSet() {
        let model = NSManagedObjectModel()
        let a = CoreDataObjectModel.model(model)
        let b = CoreDataObjectModel.model(model)
        let set: Set<CoreDataObjectModel> = [a, b]
        XCTAssertEqual(set.count, 1)
    }
}
