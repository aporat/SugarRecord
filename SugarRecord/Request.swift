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

    public func fetch() throws -> [T] {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.fetch(self)
    }

    public func fetch(_ requestable: any Requestable) throws -> [T] {
        try requestable.requestContext().fetch(self)
    }

    public func query(attributes: [String]) throws -> [[String: Any]] {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.query(self, attributes: attributes)
    }

    public func queryOne(attributes: [String]) throws -> [String: Any]? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.queryOne(self, attributes: attributes)
    }

    public func querySet(attribute: String) throws -> Set<String>? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.querySet(self, attribute: attribute)
    }

    public func fetchOne() throws -> T? {
        guard let ctx = context else { throw StorageError.invalidOperation("FetchRequest has no context") }
        return try ctx.fetchOne(self)
    }

    public func count() -> Int {
        guard let ctx = context else { return 0 }
        return ctx.count(self)
    }

    // MARK: - Public Builder Methods

    public func filtered(with predicate: NSPredicate) -> FetchRequest<T> {
        request(withPredicate: predicate)
    }

    public func filtered(with key: String, equalTo value: String) -> FetchRequest<T> {
        request(withPredicate: NSPredicate(format: "\(key) == %@", value))
    }

    public func filtered(with key: String, in value: [String]) -> FetchRequest<T> {
        request(withPredicate: NSPredicate(format: "\(key) IN %@", value))
    }

    public func filtered(with key: String, notIn value: [String]) -> FetchRequest<T> {
        request(withPredicate: NSPredicate(format: "NOT (\(key) IN %@)", value))
    }

    public func sorted(with sortDescriptor: NSSortDescriptor) -> FetchRequest<T> {
        request(withSortDescriptor: sortDescriptor)
    }

    public func sorted(with key: String?, ascending: Bool, comparator cmptr: @escaping Comparator) -> FetchRequest<T> {
        request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, comparator: cmptr))
    }

    public func sorted(with key: String?, ascending: Bool) -> FetchRequest<T> {
        request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending))
    }

    public func sorted(with key: String?, ascending: Bool, selector: Selector) -> FetchRequest<T> {
        request(withSortDescriptor: NSSortDescriptor(key: key, ascending: ascending, selector: selector))
    }

    /// Optional niceties (non-breaking additions)
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
