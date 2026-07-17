import Foundation

struct ObserverRegistrationRetryPolicy: Sendable, Equatable {
  let maxRetries: Int
  let baseDelay: Duration

  static let `default` = ObserverRegistrationRetryPolicy(
    maxRetries: 3,
    baseDelay: .milliseconds(50))

  enum Decision: Equatable {
    case retry(after: Duration)
    case giveUp(Reason)
  }

  enum Reason: Equatable {
    case applicationNoLongerFrontmost
    case retriesExhausted
  }

  func decision(after failedAttempt: Int, sameApplicationFrontmost: Bool) -> Decision {
    guard sameApplicationFrontmost else { return .giveUp(.applicationNoLongerFrontmost) }
    guard failedAttempt < maxRetries else { return .giveUp(.retriesExhausted) }
    let exponent = min(max(failedAttempt, 0), 6)
    return .retry(after: baseDelay * Double(1 << exponent))
  }
}
