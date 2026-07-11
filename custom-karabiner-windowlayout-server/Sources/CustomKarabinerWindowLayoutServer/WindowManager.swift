@preconcurrency import AppKit
import ApplicationServices
import Foundation

@MainActor
enum WindowManager {
  static func openAndArrange(command: LayoutCommand) async {
    guard command.version == 1, command.command == "open_and_layout" else { return }
    guard AXIsProcessTrusted() else {
      fputs("custom-karabiner-windowlayout-server needs Accessibility permission.\n", stderr)
      return
    }
    guard let screen = screenUnderMouse() else {
      fputs("custom-karabiner-windowlayout-server could not determine the target screen.\n", stderr)
      return
    }
    guard
      let applicationURL = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: command.bundleIdentifier)
    else {
      fputs(
        "custom-karabiner-windowlayout-server could not find \(command.bundleIdentifier).\n", stderr
      )
      return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    configuration.addsToRecentItems = false
    NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) {
      _, error in
      if let error {
        fputs("custom-karabiner-windowlayout-server could not open the app: \(error)\n", stderr)
      }
    }

    guard let application = await waitForApplication(command.bundleIdentifier) else {
      fputs(
        "custom-karabiner-windowlayout-server timed out opening \(command.bundleIdentifier).\n",
        stderr)
      return
    }
    application.activate(options: [.activateAllWindows])

    let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
    AXUIElementSetMessagingTimeout(applicationElement, 1.0)
    guard let windows = await waitForWindows(applicationElement) else {
      fputs(
        "custom-karabiner-windowlayout-server found no resizable windows for \(command.bundleIdentifier).\n",
        stderr)
      return
    }

    let orderedWindows = frontmostFirst(windows, applicationElement: applicationElement)
    let targetWindows = orderedWindows.enumerated().compactMap { index, window in
      index == 0 || centerIsOnScreen(window, screen: screen) ? window : nil
    }
    let frames = LayoutCalculator.frames(
      command: command,
      screen: screen,
      windowCount: targetWindows.count)

    for index in targetWindows.indices.reversed() {
      setFrame(frames[index], window: targetWindows[index])
    }

    if let frontWindow = targetWindows.first {
      AXUIElementPerformAction(frontWindow, kAXRaiseAction as CFString)
      AXUIElementSetAttributeValue(
        applicationElement,
        kAXFocusedWindowAttribute as CFString,
        frontWindow)
    }
    application.activate(options: [.activateAllWindows])
  }

  private static func waitForApplication(_ bundleIdentifier: String) async -> NSRunningApplication?
  {
    for _ in 0..<200 {
      if Task.isCancelled { return nil }
      if let application = NSRunningApplication.runningApplications(
        withBundleIdentifier: bundleIdentifier
      ).first {
        return application
      }
      try? await Task.sleep(for: .milliseconds(25))
    }
    return nil
  }

  private static func waitForWindows(_ application: AXUIElement) async -> [AXUIElement]? {
    for _ in 0..<200 {
      if Task.isCancelled { return nil }
      let windows = copyWindows(application).filter(isUsableWindow)
      if !windows.isEmpty { return windows }
      try? await Task.sleep(for: .milliseconds(25))
    }
    return nil
  }

  private static func screenUnderMouse() -> ScreenGeometry? {
    let screens = NSScreen.screens
    guard let primaryFrame = screens.first?.frame else { return nil }
    let mouse = NSEvent.mouseLocation
    let screen = screens.first { $0.frame.contains(mouse) } ?? screens.first
    guard let screen else { return nil }

    return ScreenGeometry(
      frame: accessibilityFrame(screen.frame, primaryTop: primaryFrame.maxY),
      visibleFrame: accessibilityFrame(screen.visibleFrame, primaryTop: primaryFrame.maxY))
  }

  private static func accessibilityFrame(_ frame: CGRect, primaryTop: CGFloat) -> CGRect {
    CGRect(
      x: frame.minX,
      y: primaryTop - frame.maxY,
      width: frame.width,
      height: frame.height)
  }

  private static func copyWindows(_ application: AXUIElement) -> [AXUIElement] {
    var value: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(
        application,
        kAXWindowsAttribute as CFString,
        &value) == .success,
      let windows = value as? [AXUIElement]
    else {
      return []
    }
    return windows
  }

  private static func frontmostFirst(
    _ windows: [AXUIElement],
    applicationElement: AXUIElement
  ) -> [AXUIElement] {
    guard
      let focusedWindow = copyElementAttribute(
        applicationElement,
        attribute: kAXFocusedWindowAttribute),
      let focusedIndex = windows.firstIndex(where: { CFEqual($0, focusedWindow) })
    else {
      return windows
    }

    var ordered = windows
    let focused = ordered.remove(at: focusedIndex)
    ordered.insert(focused, at: 0)
    return ordered
  }

  private static func isUsableWindow(_ window: AXUIElement) -> Bool {
    guard copyStringAttribute(window, attribute: kAXRoleAttribute) == kAXWindowRole else {
      return false
    }
    if copyStringAttribute(window, attribute: kAXSubroleAttribute) != kAXStandardWindowSubrole {
      return false
    }
    if copyBoolAttribute(window, attribute: kAXMinimizedAttribute) == true {
      return false
    }
    if copyBoolAttribute(window, attribute: "AXFullScreen") == true {
      return false
    }
    guard let frame = copyFrame(window) else { return false }
    return frame.width > 0 && frame.height > 0
  }

  private static func centerIsOnScreen(_ window: AXUIElement, screen: ScreenGeometry) -> Bool {
    guard let frame = copyFrame(window) else { return false }
    return screen.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
  }

  private static func copyElementAttribute(
    _ element: AXUIElement,
    attribute: String
  ) -> AXUIElement? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
      let value,
      CFGetTypeID(value) == AXUIElementGetTypeID()
    else {
      return nil
    }
    return unsafeDowncast(value, to: AXUIElement.self)
  }

  private static func copyStringAttribute(
    _ element: AXUIElement,
    attribute: String
  ) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }
    return value as? String
  }

  private static func copyBoolAttribute(
    _ element: AXUIElement,
    attribute: String
  ) -> Bool? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }
    return value as? Bool
  }

  private static func copyFrame(_ window: AXUIElement) -> CGRect? {
    guard let position = copyPointAttribute(window, attribute: kAXPositionAttribute),
      let size = copySizeAttribute(window, attribute: kAXSizeAttribute)
    else {
      return nil
    }
    return CGRect(origin: position, size: size)
  }

  private static func copyPointAttribute(
    _ element: AXUIElement,
    attribute: String
  ) -> CGPoint? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
      let value,
      CFGetTypeID(value) == AXValueGetTypeID()
    else {
      return nil
    }

    let axValue = unsafeDowncast(value, to: AXValue.self)
    var point = CGPoint.zero
    guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
    return point
  }

  private static func copySizeAttribute(
    _ element: AXUIElement,
    attribute: String
  ) -> CGSize? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
      let value,
      CFGetTypeID(value) == AXValueGetTypeID()
    else {
      return nil
    }

    let axValue = unsafeDowncast(value, to: AXValue.self)
    var size = CGSize.zero
    guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
    return size
  }

  private static func setFrame(_ frame: CGRect, window: AXUIElement) {
    setPointAttribute(window, attribute: kAXPositionAttribute, point: frame.origin)
    setSizeAttribute(window, attribute: kAXSizeAttribute, size: frame.size)
    setPointAttribute(window, attribute: kAXPositionAttribute, point: frame.origin)
  }

  private static func setPointAttribute(
    _ element: AXUIElement,
    attribute: String,
    point: CGPoint
  ) {
    var point = point
    guard let value = AXValueCreate(.cgPoint, &point) else { return }
    AXUIElementSetAttributeValue(element, attribute as CFString, value)
  }

  private static func setSizeAttribute(
    _ element: AXUIElement,
    attribute: String,
    size: CGSize
  ) {
    var size = size
    guard let value = AXValueCreate(.cgSize, &size) else { return }
    AXUIElementSetAttributeValue(element, attribute as CFString, value)
  }
}
