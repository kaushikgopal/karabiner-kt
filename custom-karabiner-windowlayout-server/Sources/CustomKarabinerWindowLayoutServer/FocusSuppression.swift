import Foundation

struct FocusSuppression<Key: Equatable> {
  enum Outcome: Equatable {
    case suppressed
    case resetCleared
    case expiredCleared
    case noSuppression
  }

  private let ttl: Duration
  private var active: (key: Key, deadline: ContinuousClock.Instant)?

  init(ttl: Duration) {
    self.ttl = ttl
  }

  mutating func register(key: Key, now: ContinuousClock.Instant) {
    active = (key: key, deadline: now + ttl)
  }

  mutating func decide(key: Key, now: ContinuousClock.Instant) -> Outcome {
    guard let active else { return .noSuppression }
    if now >= active.deadline {
      self.active = nil
      return .expiredCleared
    }
    if active.key == key {
      return .suppressed
    }
    self.active = nil
    return .resetCleared
  }

  mutating func clear() {
    active = nil
  }
}
