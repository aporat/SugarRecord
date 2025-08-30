import Foundation

public struct FetchRequest<T: Entity>: Equatable {
    // MARK: - Attributes
    
    public let sortDescriptor: NSSortDescriptor?
    public let predicate: NSPredicate?
    public let fetchOffset: Int
    public let fetchLimit: Int
    let context: (any Context)?
    
    // MARK: - Init
    
    public init(
        _ requestable: (any Requestable)? = nil,
        sortDescriptor: NSSortDescriptor? = nil,
        predicate: NSPredicate? = nil,
        fetchOffset: Int = 0,
        fetchLimit: Int = 0
    ) {
        self.context = requestable?.requestContext()
        self.sortDescriptor = sortDescriptor
        self.predicate = predicate
        self.fetchOffset = fetchOffset
        self.fetchLimit = fetchLimit
    }
    
    public init(
        _ context: any Context,
        predicate: NSPredicate? = nil,
        fetchOffset: Int = 0,
        fetchLimit: Int = 0
    ) {
        self.context = context
        self.sortDescriptor = nil
        self.predicate = predicate
        self.fetchOffset = fetchOffset
        self.fetchLimit = fetchLimit
    }
    
    // MARK: - Public Fetching Methods
    
    public func fetchAll() throws -> [T] {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.fetchAll(self)
    }
    
    public func fetchAll(from requestable: any Requestable) throws -> [T] {
        try requestable.requestContext().fetchAll(self)
    }
    
    public func fetchFirst() throws -> T? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.fetchFirst(self)
    }
    
    public func count() -> Int {
        guard let ctx = context else { return 0 }
        return ctx.countEntities(self)
    }
    
    // MARK: - Public Query Methods
    
    public func queryAttributes(_ attributes: [String]) throws -> [[String: Any]] {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.queryAttributes(self, attributes: attributes)
    }
    
    public func queryFirstAttributes(_ attributes: [String]) throws -> [String: Any]? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.queryFirstAttributes(self, attributes: attributes)
    }
    
    public func queryAttributeValues(_ attribute: String) throws -> [String]? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.queryAttributeValues(self, attribute: attribute)
    }
    
    public func queryDistinctAttributeValues(_ attribute: String) throws -> Set<String>? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.queryDistinctAttributeValues(self, attribute: attribute)
    }
    
    // MARK: - Builder Methods
    
    public func filtered(with predicate: NSPredicate) -> FetchRequest<T> {
        request(withPredicate: predicate)
    }
    
    public func filtered(key: String, equalTo value: String) -> FetchRequest<T> {
        request(withPredicate: NSPredicate(format: "\(key) == %@", value))
    }
    
    public func filtered(key: String, in values: [String]) -> FetchRequest<T> {
        request(withPredicate: NSPredicate(format: "\(key) IN %@", values))
    }
    
    public func filtered(key: String, notIn values: [String]) -> FetchRequest<T> {
        request(withPredicate: NSPredicate(format: "NOT (\(key) IN %@)", values))
    }
    
    public func sorted(by sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        request(withSortDescriptor: sortDescriptor)
    }
    
    public func sorted(key: String?, ascending: Bool) -> FetchRequest<T> {
        request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending))
    }
    
    public func sorted(key: String?, ascending: Bool, comparator: @escaping Comparator) -> FetchRequest<T> {
        request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, comparator: comparator))
    }
    
    public func sorted(key: String?, ascending: Bool, selector: Selector) -> FetchRequest<T> {
        request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, selector: selector))
    }
    
    public func offset(_ value: Int) -> FetchRequest<T> {
        FetchRequest<T>(context,
                        sortDescriptor: sortDescriptor,
                        predicate: predicate,
                        fetchOffset: value,
                        fetchLimit: fetchLimit)
    }
    
    public func limit(_ value: Int) -> FetchRequest<T> {
        FetchRequest<T>(context,
                        sortDescriptor: sortDescriptor,
                        predicate: predicate,
                        fetchOffset: fetchOffset,
                        fetchLimit: value)
    }
    
    // MARK: - Internal
    
    func request(withPredicate predicate: NSPredicate) -> FetchRequest<T> {
        FetchRequest<T>(context,
                        sortDescriptor: sortDescriptor,
                        predicate: predicate,
                        fetchOffset: fetchOffset,
                        fetchLimit: fetchLimit)
    }
    
    func request(withSortDescriptor sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        FetchRequest<T>(context,
                        sortDescriptor: sortDescriptor,
                        predicate: predicate,
                        fetchOffset: fetchOffset,
                        fetchLimit: fetchLimit)
    }
}

// MARK: - Equatable

extension FetchRequest {
    public static func == (lhs: FetchRequest<T>, rhs: FetchRequest<T>) -> Bool {
        lhs.sortDescriptor == rhs.sortDescriptor &&
        lhs.predicate == rhs.predicate &&
        lhs.fetchOffset == rhs.fetchOffset &&
        lhs.fetchLimit == rhs.fetchLimit
    }
}
