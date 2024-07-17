final class UncheckedBox<Value>: @unchecked Sendable {
  var wrappedValue: Value
  init(wrappedValue: Value) {
    self.wrappedValue = wrappedValue
  }
}
