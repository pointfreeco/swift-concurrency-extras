#if os(iOS)
  import ConcurrencyExtras
  import SwiftUI

  @available(iOS 15, *)
  private let sendable: @Sendable () async -> AsyncStream<Void> = {
    UncheckedSendable(
      NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    )
    .eraseToStream()
  }

  @available(iOS 15, *)
  private let sendableInitializer: @Sendable () async -> AsyncStream<Void> = {
    AsyncStream(
      UncheckedSendable(
        NotificationCenter.default
          .notifications(named: UIApplication.userDidTakeScreenshotNotification)
          .map { _ in }
      )
    )
  }

  @available(iOS 15, *)
  private let mainActor: @MainActor () -> AsyncStream<Void> = {
    UncheckedSendable(
      NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    )
    .eraseToStream()
  }

  @available(iOS 15, *)
  private let sendableThrowing: @Sendable () async -> AsyncThrowingStream<Void, Error> = {
    UncheckedSendable(
      NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    )
    .eraseToThrowingStream()
  }

  @available(iOS 15, *)
  private let mainActorThrowing: @MainActor () -> AsyncThrowingStream<Void, Error> = {
    UncheckedSendable(
      NotificationCenter.default
        .notifications(named: UIApplication.userDidTakeScreenshotNotification)
        .map { _ in }
    )
    .eraseToThrowingStream()
  }
#endif
