import Foundation

#if !(os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
  extension NSLock {
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
      self.lock()
      defer { self.unlock() }
      return try body()
    }
  }
#endif
