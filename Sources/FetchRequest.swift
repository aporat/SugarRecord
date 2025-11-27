import Foundation
import CoreData

public struct FetchRequest<T: NSManagedObject>: @unchecked Sendable {
    
    public let sortDescriptor: NSSortDescriptor?
    public let predicate: NSPredicate?
    public let fetchOffset: Int
    public let fetchLimit: Int
    public let context: NSManagedObjectContext?
    
    public init(
        _ context: NSManagedObjectContext? = nil,
        sortDescriptor: NSSortDescriptor? = nil,
        predicate: NSPredicate? = nil,
        fetchOffset: Int = 0,
        fetchLimit: Int = 0
    ) {
        self.context = context
        self.sortDescriptor = sortDescriptor
        self.predicate = predicate
        self.fetchOffset = fetchOffset
        self.fetchLimit = fetchLimit
    }
    
    // MARK: - Execution
    
    public func fetch() throws -> [T] {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try ctx.fetch(self)
    }
    
    public func fetchOne() throws -> T? {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try ctx.fetchOne(self)
    }
    
    public func count() -> Int {
        guard let ctx = context else { return 0 }
        return ctx.count(self)
    }
    
    // MARK: - Async Execution
    
    public func fetch() async throws -> [T] {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try await ctx.fetch(self)
    }
    
    public func fetchOne() async throws -> T? {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try await ctx.fetchOne(self)
    }
    
    public func count() async -> Int {
        guard let ctx = context else { return 0 }
        return await ctx.count(self)
    }
    
    // MARK: - Query Helpers (Dictionary / Set)
    
    public func query(attributes: [String]) throws -> [[String: Any]] {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try ctx.query(self, attributes: attributes)
    }
    
    public func queryOne(attributes: [String]) throws -> String? {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try ctx.queryOne(self, attribute: attributes.first ?? "") 
    }
    
    // Overload for specific attribute list fetch
    public func queryOne(attribute: String) throws -> String? {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try ctx.queryOne(self, attribute: attribute)
    }
    
    public func querySet(attribute: String) throws -> Set<String> {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try ctx.querySet(self, attribute: attribute)
    }
    
    // Async Versions
    
    public func query(attributes: [String]) async throws -> [[String: Any]] {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try await ctx.query(self, attributes: attributes)
    }
    
    public func queryOne(attribute: String) async throws -> String? {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try await ctx.queryOne(self, attribute: attribute)
    }
    
    public func querySet(attribute: String) async throws -> Set<String> {
        guard let ctx = context else { throw CoreDataError.contextRequired }
        return try await ctx.querySet(self, attribute: attribute)
    }
    
    // MARK: - Builders
    
    public func filtered(with predicate: NSPredicate) -> FetchRequest<T> {
        copy(predicate: predicate)
    }
    
    public func filtered(key: String, equalTo value: Any) -> FetchRequest<T> {
        copy(predicate: NSPredicate(format: "%K == %@", argumentArray: [key, value]))
    }
    
    public func filtered(key: String, in values: [Any]) -> FetchRequest<T> {
        copy(predicate: NSPredicate(format: "%K IN %@", argumentArray: [key, values]))
    }
    
    public func filtered(key: String, notIn values: [Any]) -> FetchRequest<T> {
        copy(predicate: NSPredicate(format: "NOT (%K IN %@)", argumentArray: [key, values]))
    }
    
    public func sorted(key: String?, ascending: Bool) -> FetchRequest<T> {
        copy(sortDescriptor: NSSortDescriptor(key: key, ascending: ascending))
    }
    
    public func limit(_ value: Int) -> FetchRequest<T> {
        copy(fetchLimit: value)
    }
    
    public func offset(_ value: Int) -> FetchRequest<T> {
        copy(fetchOffset: value)
    }
    
    private func copy(sortDescriptor: NSSortDescriptor? = nil, predicate: NSPredicate? = nil, fetchOffset: Int? = nil, fetchLimit: Int? = nil) -> FetchRequest<T> {
        FetchRequest<T>(
            self.context,
            sortDescriptor: sortDescriptor ?? self.sortDescriptor,
            predicate: predicate ?? self.predicate,
            fetchOffset: fetchOffset ?? self.fetchOffset,
            fetchLimit: fetchLimit ?? self.fetchLimit
        )
    }
}
