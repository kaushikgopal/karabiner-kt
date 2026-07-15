@preconcurrency import AppKit
import Foundation

@MainActor
enum CommandCoordinator {
  private static var tasks: [String: Task<Void, Never>] = [:]
  private static var cycleTracker = CycleTracker<AXWindowToken>()
  private static let focusMonitor = FocusMonitor {
    cycleTracker.focusedWindowDidChange()
  }
  private static let activationMonitor = WorkspaceActivationMonitor { application in
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
    tasks.values.forEach { $0.cancel() }
    tasks.removeAll()
    cycleTracker.cyclePolicy = command.cyclePolicy
    tasks[command.taskIdentifier] = Task {
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
}
