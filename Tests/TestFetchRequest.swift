import XCTest
import CoreData
@testable import SugarRecord

final class TestFetchRequest: XCTestCase {

    var db: SugarRecord!

    override func setUpWithError() throws {
        db = try TestModelBuilder.makeInMemoryStore()
    }

    override func tearDownWithError() throws {
        db = nil
    }

    // MARK: - Init Defaults

    func testDefaultValues() {
        let request = FetchRequest<MockUser>()
        XCTAssertNil(request.context)
        XCTAssertNil(request.sortDescriptor)
        XCTAssertNil(request.predicate)
        XCTAssertEqual(request.fetchOffset, 0)
        XCTAssertEqual(request.fetchLimit, 0)
    }

    func testInitWithContext() {
        let request = FetchRequest<MockUser>(db.mainContext)
        XCTAssertNotNil(request.context)
    }

    // MARK: - Builders

    func testFilteredWithPredicate() {
        let predicate = NSPredicate(format: "name == %@", "Test")
        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(with: predicate)
        XCTAssertEqual(request.predicate, predicate)
    }

    func testFilteredKeyEqualTo() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "name", equalTo: "Alice")
        XCTAssertNotNil(request.predicate)
    }

    func testFilteredKeyIn() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "name", in: ["Alice", "Bob"])
        XCTAssertNotNil(request.predicate)
    }

    func testFilteredKeyNotIn() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "name", notIn: ["Alice"])
        XCTAssertNotNil(request.predicate)
    }

    func testSorted() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .sorted(key: "age", ascending: false)
        XCTAssertNotNil(request.sortDescriptor)
        XCTAssertEqual(request.sortDescriptor?.key, "age")
        XCTAssertEqual(request.sortDescriptor?.ascending, false)
    }

    func testLimit() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .limit(5)
        XCTAssertEqual(request.fetchLimit, 5)
    }

    func testOffset() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .offset(10)
        XCTAssertEqual(request.fetchOffset, 10)
    }

    func testChainingPreservesValues() {
        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "age", equalTo: 25)
            .sorted(key: "name", ascending: true)
            .limit(10)
            .offset(5)

        XCTAssertNotNil(request.predicate)
        XCTAssertNotNil(request.sortDescriptor)
        XCTAssertEqual(request.sortDescriptor?.key, "name")
        XCTAssertEqual(request.fetchLimit, 10)
        XCTAssertEqual(request.fetchOffset, 5)
        XCTAssertNotNil(request.context)
    }

    // MARK: - Contextless Operations

    func testFetchWithoutContextThrows() {
        let request = FetchRequest<MockUser>()
        XCTAssertThrowsError(try request.fetch()) { error in
            XCTAssertTrue(error is CoreDataError)
        }
    }

    func testFetchOneWithoutContextThrows() {
        let request = FetchRequest<MockUser>()
        XCTAssertThrowsError(try request.fetchOne()) { error in
            XCTAssertTrue(error is CoreDataError)
        }
    }

    func testCountWithoutContextReturnsZero() {
        let request = FetchRequest<MockUser>()
        XCTAssertEqual(request.count(), 0)
    }

    func testQueryWithoutContextThrows() {
        let request = FetchRequest<MockUser>()
        XCTAssertThrowsError(try request.query(attributes: ["name"])) { error in
            XCTAssertTrue(error is CoreDataError)
        }
    }

    func testQueryOneWithoutContextThrows() {
        let request = FetchRequest<MockUser>()
        XCTAssertThrowsError(try request.queryOne(attribute: "name")) { error in
            XCTAssertTrue(error is CoreDataError)
        }
    }

    func testQuerySetWithoutContextThrows() {
        let request = FetchRequest<MockUser>()
        XCTAssertThrowsError(try request.querySet(attribute: "name")) { error in
            XCTAssertTrue(error is CoreDataError)
        }
    }

    // MARK: - Async Contextless Operations

    func testAsyncFetchWithoutContextThrows() async {
        let request = FetchRequest<MockUser>()
        do {
            _ = try await request.fetch() as [MockUser]
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is CoreDataError)
        }
    }

    func testAsyncFetchOneWithoutContextThrows() async {
        let request = FetchRequest<MockUser>()
        do {
            _ = try await request.fetchOne() as MockUser?
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is CoreDataError)
        }
    }

    func testAsyncCountWithoutContextReturnsZero() async {
        let request = FetchRequest<MockUser>()
        let count: Int = await request.count()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Fetch with Context

    func testFetchReturnsInsertedObjects() throws {
        let user: MockUser = try db.mainContext.new()
        user.name = "Test"
        user.age = 10
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
        let results = try request.fetch()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Test")
    }

    func testFetchOneReturnsFirstMatch() throws {
        let u1: MockUser = try db.mainContext.new(); u1.name = "A"; u1.age = 1
        let u2: MockUser = try db.mainContext.new(); u2.name = "B"; u2.age = 2
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "name", equalTo: "B")
        let result = try request.fetchOne()
        XCTAssertEqual(result?.name, "B")
    }

    func testCountReturnsCorrectNumber() throws {
        for i in 0..<5 {
            let user: MockUser = try db.mainContext.new()
            user.name = "U\(i)"
            user.age = Int16(i)
        }
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
        XCTAssertEqual(request.count(), 5)
    }

    func testLimitRestrictsResults() throws {
        for i in 0..<5 {
            let user: MockUser = try db.mainContext.new()
            user.name = "U\(i)"
            user.age = Int16(i)
        }
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
            .sorted(key: "age", ascending: true)
            .limit(2)
        let results = try request.fetch()
        XCTAssertEqual(results.count, 2)
    }

    func testFilteredKeyInReturnsMatchingObjects() throws {
        let u1: MockUser = try db.mainContext.new(); u1.name = "Alice"; u1.age = 10
        let u2: MockUser = try db.mainContext.new(); u2.name = "Bob"; u2.age = 20
        let u3: MockUser = try db.mainContext.new(); u3.name = "Charlie"; u3.age = 30
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "name", in: ["Alice", "Charlie"])
            .sorted(key: "name", ascending: true)
        let results = try request.fetch()
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.name, "Alice")
        XCTAssertEqual(results.last?.name, "Charlie")
    }

    func testFilteredKeyNotInExcludesObjects() throws {
        let u1: MockUser = try db.mainContext.new(); u1.name = "Alice"; u1.age = 10
        let u2: MockUser = try db.mainContext.new(); u2.name = "Bob"; u2.age = 20
        let u3: MockUser = try db.mainContext.new(); u3.name = "Charlie"; u3.age = 30
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "name", notIn: ["Bob"])
            .sorted(key: "name", ascending: true)
        let results = try request.fetch()
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.name, "Alice")
        XCTAssertEqual(results.last?.name, "Charlie")
    }
}
