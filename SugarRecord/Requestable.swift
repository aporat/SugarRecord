import Foundation

public protocol Requestable {
    /// The default `Context` used when building fetch requests.
    func requestContext() -> any Context
    
    /// Create a `FetchRequest` for the given entity type.
    func request<T: Entity>(_ model: T.Type) -> FetchRequest<T>
    
    /// Convenience: infer `T` from the call site (e.g. `request() as FetchRequest<User>`).
    func request<T: Entity>() -> FetchRequest<T>
}

public extension Requestable where Self: Context {
    @inline(__always)
    func requestContext() -> any Context { self }
    
    @inline(__always)
    func request<T: Entity>(_: T.Type) -> FetchRequest<T> { FetchRequest<T>(self) }
    
    @inline(__always)
    func request<T: Entity>() -> FetchRequest<T> { FetchRequest<T>(self) }
}

public extension Requestable where Self: Storage {
    @inline(__always)
    func requestContext() -> any Context { mainContext }
    
    @inline(__always)
    func request<T: Entity>(_: T.Type) -> FetchRequest<T> { FetchRequest<T>(mainContext) }
    
    @inline(__always)
    func request<T: Entity>() -> FetchRequest<T> { FetchRequest<T>(mainContext) }
}
