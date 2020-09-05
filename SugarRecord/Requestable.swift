import Foundation

public protocol Requestable {
    func requestContext() -> Context
    func request<T>(_ model: T.Type) -> FetchRequest<T>
}

public extension Requestable where Self: Context {
    func requestContext() -> Context {
        self
    }

    func request<T>(_: T.Type) -> FetchRequest<T> {
        FetchRequest<T>(self)
    }
}

public extension Requestable where Self: Storage {
    func requestContext() -> Context {
        mainContext
    }

    func request<T>(_: T.Type) -> FetchRequest<T> {
        FetchRequest<T>(mainContext)
    }
}
