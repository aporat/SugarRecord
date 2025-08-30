import CoreData
import Foundation

public enum CoreDataOptions {
    case basic
    case migration
    
    public var settings: [String: AnyObject] {
        switch self {
        case .basic:
            return CoreDataOptions.makeOptions(inferMapping: false)
        case .migration:
            return CoreDataOptions.makeOptions(inferMapping: true)
        }
    }
    
    private static func makeOptions(inferMapping: Bool) -> [String: AnyObject] {
        let sqliteOptions: [String: String] = ["journal_mode": "DELETE"]
        
        var options: [String: AnyObject] = [:]
        options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(value: true)
        options[NSInferMappingModelAutomaticallyOption] = NSNumber(value: inferMapping)
        options[NSSQLitePragmasOption] = sqliteOptions as AnyObject
        return options
    }
}
