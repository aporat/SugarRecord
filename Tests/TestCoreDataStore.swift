import XCTest
import Foundation
@testable import SugarRecord

final class TestCoreDataStore: XCTestCase {

    // MARK: - Path

    func testInMemoryPathIsNil() {
        let store = CoreDataStore.inMemory
        XCTAssertNil(store.path)
    }

    func testNamedPathContainsName() {
        let store = CoreDataStore.named("MyDatabase.sqlite")
        XCTAssertNotNil(store.path)
        XCTAssertTrue(store.path!.lastPathComponent == "MyDatabase.sqlite")
    }

    func testURLPathMatchesInput() {
        let url = URL(fileURLWithPath: "/tmp/test.sqlite")
        let store = CoreDataStore.url(url)
        XCTAssertEqual(store.path, url)
    }

    // MARK: - Description

    func testInMemoryDescription() {
        let store = CoreDataStore.inMemory
        XCTAssertEqual(store.description, "CoreDataStore(inMemory)")
    }

    func testNamedDescription() {
        let store = CoreDataStore.named("db.sqlite")
        let desc = store.description
        XCTAssertTrue(desc.contains("CoreDataStore(named: db.sqlite)"))
    }

    func testURLDescription() {
        let url = URL(fileURLWithPath: "/tmp/test.sqlite")
        let store = CoreDataStore.url(url)
        XCTAssertTrue(store.description.contains("/tmp/test.sqlite"))
    }

    // MARK: - Equatable

    func testInMemoryEquality() {
        XCTAssertEqual(CoreDataStore.inMemory, CoreDataStore.inMemory)
    }

    func testNamedEquality() {
        XCTAssertEqual(CoreDataStore.named("a"), CoreDataStore.named("a"))
        XCTAssertNotEqual(CoreDataStore.named("a"), CoreDataStore.named("b"))
    }

    func testURLEquality() {
        let url = URL(fileURLWithPath: "/tmp/a.sqlite")
        XCTAssertEqual(CoreDataStore.url(url), CoreDataStore.url(url))
    }

    func testDifferentCasesAreNotEqual() {
        XCTAssertNotEqual(CoreDataStore.inMemory, CoreDataStore.named("test"))
    }

    // MARK: - Hashable

    func testHashableInSet() {
        let set: Set<CoreDataStore> = [.inMemory, .named("a"), .named("a")]
        XCTAssertEqual(set.count, 2)
    }
}
