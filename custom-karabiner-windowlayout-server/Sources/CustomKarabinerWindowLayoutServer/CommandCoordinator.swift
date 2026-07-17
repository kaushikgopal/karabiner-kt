@preconcurrency import AppKit
import Foundation

@MainActor
enum CommandCoordinator {
  private static var tasks: [String: Task<Void, Never>] = [:]
  private static var cycleTracker = CycleTracker<AXWindowToken>()
  private static var focusSuppression = FocusSuppression<AXWindowToken>(
    ttl: .milliseconds(200))
  private static let focusMonitor = FocusMonitor { resolvedWindow in
    handleFocusedWindowChange(resolvedWindow: resolvedWindow)
  }
  private static let activationMonitor = WorkspaceActivationMonitor { application in
    focusSuppression.clear()
    cycleTracker.applicationDidActivate(bundleIdentifier: application?.bundleIdentifier)
    focusMonitor.observe(application: application)
  }
  private static var started = false

  static func start() {
    guard !started else { return }
    started = true
    focusMonitor.observe(application: NSWorkspace.shared.frontmostApplication)
    activationMonitor.start()
  }

  static func submit(_ command: UserCommand) {
    for task in tasks.values {
      task.cancel()
    }
    tasks.removeAll()
    cycleTracker.cyclePolicy = command.cyclePolicy
    tasks[command.taskIdentifier] = Task {
      guard !Task.isCancelled else { return }
      await WindowManager.execute(command: command)
    }
  }

  static func nextCycleIndex(
    commandIdentifier: String,
    window: AXWindowToken,
    stepCount: Int,
    reset: Bool = false
  ) -> Int {
    cycleTracker.nextIndex(
      commandIdentifier: commandIdentifier,
      window: window,
      stepCount: stepCount,
      reset: reset)
  }

  static func registerFocusSuppression(for window: AXWindowToken) {
    focusSuppression.register(key: window, now: ContinuousClock.now)
  }

  private static func handleFocusedWindowChange(resolvedWindow: AXWindowToken?) {
    guard let resolvedWindow else {
      focusSuppression.clear()
      cycleTracker.focusedWindowDidChange()
      return
    }
    switch focusSuppression.decide(key: resolvedWindow, now: ContinuousClock.now) {
    case .suppressed:
      break
    case .resetCleared, .expiredCleared, .noSuppression:
      cycleTracker.focusedWindowDidChange()
    }
  }
}
