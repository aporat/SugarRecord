@preconcurrency import Foundation

/// A type that can be bridged to and from an `NSSortDescriptor`.
public protocol NSSortDescriptorConvertible: Sendable {
    /// Initialize from an existing sort descriptor.
    init(sortDescriptor: NSSortDescriptor)
    
    /// The bridged sort descriptor.
    var sortDescriptor: NSSortDescriptor { get }
}
