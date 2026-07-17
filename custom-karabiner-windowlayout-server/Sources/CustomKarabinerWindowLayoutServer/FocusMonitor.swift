@preconcurrency import AppKit
import ApplicationServices
import Foundation

private let focusedWindowChangedCallback: AXObserverCallback = {
  callbackObserver, _, notification, context in
  guard notification as String == kAXFocusedWindowChangedNotification,
    let context
  else {
    return
  }

  let monitor = Unmanaged<FocusMonitor>.fromOpaque(context).takeUnretainedValue()
  let callbackObserverID = ObjectIdentifier(callbackObserver)
  MainActor.assumeIsolated {
    monitor.focusedWindowDidChange(from: callbackObserverID)
  }
}

@MainActor
final class FocusMonitor {
  private let onFocusedWindowChange: @MainActor (AXWindowToken?) -> Void
  private let retryPolicy: ObserverRegistrationRetryPolicy
  private var observer: AXObserver?
  private var applicationElement: AXUIElement?
  private var observedBundleIdentifier: String?
  private var observedProcessIdentifier: pid_t?
  private var registrationTask: Task<Void, Never>?

  init(
    onFocusedWindowChange: @escaping @MainActor (AXWindowToken?) -> Void,
    retryPolicy: ObserverRegistrationRetryPolicy = .default
  ) {
    self.onFocusedWindowChange = onFocusedWindowChange
    self.retryPolicy = retryPolicy
  }

  func observe(application: NSRunningApplication?) {
    cancelRegistrationTask()
    stopObserving()
    guard let application else { return }

    let pid = application.processIdentifier
    observedBundleIdentifier = application.bundleIdentifier
    observedProcessIdentifier = pid
    registrationTask = Task { [weak self] in
      await self?.registerObserver(pid: pid)
    }
  }

  fileprivate func focusedWindowDidChange(from callbackObserverID: ObjectIdentifier) {
    guard let observer, ObjectIdentifier(observer) == callbackObserverID else { return }
    onFocusedWindowChange(resolvedFocusedWindow())
  }

  private func resolvedFocusedWindow() -> AXWindowToken? {
    guard let applicationElement,
      let bundleIdentifier = observedBundleIdentifier,
      let processIdentifier = observedProcessIdentifier,
      let focused = copyFocusedWindow(from: applicationElement)
    else {
      return nil
    }
    return AXWindowToken(
      bundleIdentifier: bundleIdentifier,
      processIdentifier: processIdentifier,
      element: focused)
  }

  private func copyFocusedWindow(from applicationElement: AXUIElement) -> AXUIElement? {
    var value: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(
        applicationElement,
        kAXFocusedWindowAttribute as CFString,
        &value) == .success,
      let value,
      CFGetTypeID(value) == AXUIElementGetTypeID()
    else {
      return nil
    }
    return unsafeDowncast(value, to: AXUIElement.self)
  }

  private func cancelRegistrationTask() {
    registrationTask?.cancel()
    registrationTask = nil
  }

  private func registerObserver(pid: pid_t) async {
    var attempt = 0
    while !Task.isCancelled {
      let sameApplicationFrontmost =
        NSWorkspace.shared.frontmostApplication?.processIdentifier == pid

      guard sameApplicationFrontmost else { return }

      switch attemptRegistration(pid: pid) {
      case .success:
        return
      case .failed(let failure):
        fputs(
          "custom-karabiner-windowlayout-server \(failure.stage) failed"
            + " pid=\(pid) attempt=\(attempt) error=\(failure.error)\n",
          stderr)
        guard failure.error == .cannotComplete || failure.error == .failure else { return }

        let decision = retryPolicy.decision(
          after: attempt,
          sameApplicationFrontmost: sameApplicationFrontmost)
        switch decision {
        case .retry(after: let delay):
          try? await Task.sleep(for: delay)
        case .giveUp:
          return
        }
      }

      attempt += 1
    }
  }

  private enum RegistrationStage: String {
    case create = "AXObserverCreate"
    case addNotification = "AXObserverAddNotification"
  }

  private struct RegistrationFailure {
    let error: AXError
    let stage: RegistrationStage
  }

  private enum RegistrationOutcome {
    case success
    case failed(RegistrationFailure)
  }

  private func attemptRegistration(pid: pid_t) -> RegistrationOutcome {
    var newObserver: AXObserver?
    let createResult = AXObserverCreate(
      pid,
      focusedWindowChangedCallback,
      &newObserver)
    guard createResult == .success, let newObserver else {
      return .failed(RegistrationFailure(error: createResult, stage: .create))
    }

    let newApplicationElement = AXUIElementCreateApplication(pid)
    let context = Unmanaged.passUnretained(self).toOpaque()
    let addResult = AXObserverAddNotification(
      newObserver,
      newApplicationElement,
      kAXFocusedWindowChangedNotification as CFString,
      context)
    guard addResult == .success else {
      return .failed(RegistrationFailure(error: addResult, stage: .addNotification))
    }

    let runLoop = CFRunLoopGetMain()
    let source = AXObserverGetRunLoopSource(newObserver)
    CFRunLoopAddSource(runLoop, source, .commonModes)
    observer = newObserver
    applicationElement = newApplicationElement
    return .success
  }

  private func stopObserving() {
    if let observer {
      if let applicationElement {
        AXObserverRemoveNotification(
          observer,
          applicationElement,
          kAXFocusedWindowChangedNotification as CFString)
      }
      let runLoop = CFRunLoopGetMain()
      CFRunLoopRemoveSource(runLoop, AXObserverGetRunLoopSource(observer), .commonModes)
    }
    self.observer = nil
    applicationElement = nil
    observedBundleIdentifier = nil
    observedProcessIdentifier = nil
  }
}
