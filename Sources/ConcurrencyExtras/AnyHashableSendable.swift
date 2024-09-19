/// A type-erased hashable, sendable value.
///
/// A sendable version of `AnyHashable` that is useful in working around the limitation that an
/// existential `any Hashable` does not conform to `Hashable`.
public struct AnyHashableSendable: Hashable, Sendable {
  public let base: any Hashable & Sendable

  /// Creates a type-erased hashable, sendable value that wraps the given instance.
  public init(_ base: some Hashable & Sendable) {
    self.base = base
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    func open<T: Equatable>(_ lhs: T) -> Bool {
      lhs == rhs as? T
    }
    return open(lhs)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

extension AnyHashableSendable: CustomDebugStringConvertible {
  public var debugDescription: String {
    "AnyHashableSendable(" + String(reflecting: base) + ")"
  }
}
extension AnyHashableSendable: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(self, children: ["value": base])
  }
}

extension AnyHashableSendable: CustomStringConvertible {
  public var description: String {
    String(describing: base)
  }
}
