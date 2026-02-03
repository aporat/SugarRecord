import XCTest
import CoreData
@testable import SugarRecord

final class TestCoreDataStack: XCTestCase {

    var db: SugarRecord!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        db = try TestModelBuilder.makeInMemoryStore()
    }

    override func tearDownWithError() throws {
        db = nil
    }

    // MARK: - Tests

    func testInsertAndFetch() throws {
        let user: MockUser = try db.mainContext.new()
        user.name = "John"
        user.age = 25
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
        let results = try db.mainContext.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "John")
        XCTAssertEqual(results.first?.age, 25)
    }

    func testDelete() throws {
        let user: MockUser = try db.mainContext.new()
        user.name = "DeleteMe"
        try db.mainContext.save()

        db.mainContext.remove(user)
        try db.mainContext.save()

        let count = db.mainContext.count(FetchRequest<MockUser>(db.mainContext))
        XCTAssertEqual(count, 0)
    }

    func testPredicates() throws {
        let u1: MockUser = try db.mainContext.new(); u1.name = "A"; u1.age = 10
        let u2: MockUser = try db.mainContext.new(); u2.name = "B"; u2.age = 20
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
            .filtered(key: "age", equalTo: 20)

        let result = try db.mainContext.fetchOne(request)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "B")
    }

    func testSorting() throws {
        let u1: MockUser = try db.mainContext.new(); u1.name = "A"; u1.age = 30
        let u2: MockUser = try db.mainContext.new(); u2.name = "B"; u2.age = 10
        try db.mainContext.save()

        let request = FetchRequest<MockUser>(db.mainContext)
            .sorted(key: "age", ascending: true)

        let results = try db.mainContext.fetch(request)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.name, "B")
        XCTAssertEqual(results.last?.name, "A")
    }

    func testAsyncBackgroundExecution() async throws {
        try await db.performBackgroundTask { context in
            let user: MockUser = try context.new()
            user.name = "Background User"
            user.age = 99
        }

        let request = FetchRequest<MockUser>(db.mainContext).filtered(key: "age", equalTo: 99)

        // Allow time for the merge notification to propagate
        try await Task.sleep(nanoseconds: 200_000_000)

        let count = await db.mainContext.count(request)
        XCTAssertEqual(count, 1, "Main context should have received the background insert")

        let user = try? await db.mainContext.fetchOne(request)
        XCTAssertEqual(user?.name, "Background User")
    }

    func testMultipleInserts() throws {
        for i in 0..<10 {
            let user: MockUser = try db.mainContext.new()
            user.name = "User\(i)"
            user.age = Int16(i)
        }
        try db.mainContext.save()

        let count = db.mainContext.count(FetchRequest<MockUser>(db.mainContext))
        XCTAssertEqual(count, 10)
    }

    func testDeleteMultipleObjects() throws {
        let u1: MockUser = try db.mainContext.new(); u1.name = "A"; u1.age = 1
        let u2: MockUser = try db.mainContext.new(); u2.name = "B"; u2.age = 2
        let u3: MockUser = try db.mainContext.new(); u3.name = "C"; u3.age = 3
        try db.mainContext.save()

        db.mainContext.remove([u1, u2])
        try db.mainContext.save()

        let count = db.mainContext.count(FetchRequest<MockUser>(db.mainContext))
        XCTAssertEqual(count, 1)

        let remaining = try db.mainContext.fetchOne(FetchRequest<MockUser>(db.mainContext))
        XCTAssertEqual(remaining?.name, "C")
    }

    func testSaveToPersistentStore() async throws {
        let user: MockUser = try db.mainContext.new()
        user.name = "PersistentUser"
        user.age = 42

        try await db.mainContext.saveToPersistentStore()

        // Verify data is accessible after persistent save
        let request = FetchRequest<MockUser>(db.mainContext).filtered(key: "name", equalTo: "PersistentUser")
        let result = try db.mainContext.fetchOne(request)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.age, 42)
    }
}
