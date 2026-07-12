@preconcurrency import AppKit
import Foundation

@MainActor
final class WorkspaceActivationMonitor: NSObject {
  private let onActivation: @MainActor (NSRunningApplication?) -> Void
  private var isObserving = false

  init(onActivation: @escaping @MainActor (NSRunningApplication?) -> Void) {
    self.onActivation = onActivation
  }

  func start() {
    guard !isObserving else { return }
    isObserving = true
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(applicationDidActivate(_:)),
      name: NSWorkspace.didActivateApplicationNotification,
      object: nil)
  }

  @objc private func applicationDidActivate(_ notification: Notification) {
    let application =
      notification.userInfo?[NSWorkspace.applicationUserInfoKey]
      as? NSRunningApplication
    onActivation(application)
  }
}
