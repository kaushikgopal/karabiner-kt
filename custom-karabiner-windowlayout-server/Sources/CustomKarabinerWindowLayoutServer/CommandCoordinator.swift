import Foundation

@MainActor
enum CommandCoordinator {
  private static var tasks: [String: Task<Void, Never>] = [:]

  static func submit(_ command: LayoutCommand) {
    tasks[command.bundleIdentifier]?.cancel()
    tasks[command.bundleIdentifier] = Task {
      await WindowManager.openAndArrange(command: command)
    }
  }
}
