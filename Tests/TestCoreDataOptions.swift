import XCTest
import CoreData
@testable import SugarRecord

final class TestCoreDataOptions: XCTestCase {

    func testBasicOptionsDoNotInferMapping() {
        let settings = CoreDataOptions.basic.settings
        let infer = settings[NSInferMappingModelAutomaticallyOption] as? Bool
        XCTAssertEqual(infer, false)
    }

    func testBasicOptionsEnableAutoMigration() {
        let settings = CoreDataOptions.basic.settings
        let migrate = settings[NSMigratePersistentStoresAutomaticallyOption] as? Bool
        XCTAssertEqual(migrate, true)
    }

    func testMigrationOptionsInferMapping() {
        let settings = CoreDataOptions.migration.settings
        let infer = settings[NSInferMappingModelAutomaticallyOption] as? Bool
        XCTAssertEqual(infer, true)
    }

    func testMigrationOptionsEnableAutoMigration() {
        let settings = CoreDataOptions.migration.settings
        let migrate = settings[NSMigratePersistentStoresAutomaticallyOption] as? Bool
        XCTAssertEqual(migrate, true)
    }

    func testSQLitePragmasDeleteJournalMode() {
        let basicPragmas = CoreDataOptions.basic.settings[NSSQLitePragmasOption] as? [String: String]
        XCTAssertEqual(basicPragmas?["journal_mode"], "DELETE")

        let migrationPragmas = CoreDataOptions.migration.settings[NSSQLitePragmasOption] as? [String: String]
        XCTAssertEqual(migrationPragmas?["journal_mode"], "DELETE")
    }
}
