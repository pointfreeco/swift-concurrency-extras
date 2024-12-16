#if compiler(>=6)
  extension Result {
    /// Creates a new result by evaluating an async throwing closure, capturing the returned value as
    /// a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A throwing closure to evaluate.
    @_transparent
    public init(catching body: () async throws(Failure) -> Success) async {
      do {
        self = .success(try await body())
      } catch {
        self = .failure(error)
      }
    }
  }
#else
  extension Result where Failure == Swift.Error {
    @_transparent
    public init(catching body: () async throws -> Success) async {
      do {
        self = .success(try await body())
      } catch {
        self = .failure(error)
      }
    }
  }
#endif
