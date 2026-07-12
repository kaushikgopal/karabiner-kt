@preconcurrency import AppKit
import ApplicationServices
import Foundation

private let focusedWindowChangedCallback: AXObserverCallback = {
  _, _, notification, context in
  guard notification as String == kAXFocusedWindowChangedNotification,
    let context
  else {
    return
  }

  let monitor = Unmanaged<FocusMonitor>.fromOpaque(context).takeUnretainedValue()
  MainActor.assumeIsolated {
    monitor.focusedWindowDidChange()
  }
}

@MainActor
final class FocusMonitor {
  private let onFocusedWindowChange: @MainActor () -> Void
  private var observer: AXObserver?
  private var applicationElement: AXUIElement?

  init(onFocusedWindowChange: @escaping @MainActor () -> Void) {
    self.onFocusedWindowChange = onFocusedWindowChange
  }

  func observe(application: NSRunningApplication?) {
    stopObserving()
    guard let application else { return }

    var newObserver: AXObserver?
    guard
      AXObserverCreate(
        application.processIdentifier,
        focusedWindowChangedCallback,
        &newObserver) == .success,
      let newObserver
    else {
      return
    }

    let newApplicationElement = AXUIElementCreateApplication(application.processIdentifier)
    let context = Unmanaged.passUnretained(self).toOpaque()
    guard
      AXObserverAddNotification(
        newObserver,
        newApplicationElement,
        kAXFocusedWindowChangedNotification as CFString,
        context) == .success
    else {
      return
    }

    observer = newObserver
    applicationElement = newApplicationElement
    CFRunLoopAddSource(
      CFRunLoopGetMain(),
      AXObserverGetRunLoopSource(newObserver),
      .defaultMode)
  }

  fileprivate func focusedWindowDidChange() {
    onFocusedWindowChange()
  }

  private func stopObserving() {
    guard let observer else { return }

    if let applicationElement {
      AXObserverRemoveNotification(
        observer,
        applicationElement,
        kAXFocusedWindowChangedNotification as CFString)
    }
    CFRunLoopRemoveSource(
      CFRunLoopGetMain(),
      AXObserverGetRunLoopSource(observer),
      .defaultMode)
    self.observer = nil
    applicationElement = nil
  }
}
