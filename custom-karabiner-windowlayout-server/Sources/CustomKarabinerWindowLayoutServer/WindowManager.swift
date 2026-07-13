@preconcurrency import AppKit
import ApplicationServices
import Foundation

struct AXWindowToken: WindowCycleToken {
  let bundleIdentifier: String
  let processIdentifier: pid_t
  let element: AXUIElement

  static func == (lhs: AXWindowToken, rhs: AXWindowToken) -> Bool {
    lhs.bundleIdentifier == rhs.bundleIdentifier
      && lhs.processIdentifier == rhs.processIdentifier
      && CFEqual(lhs.element, rhs.element)
  }
}

@MainActor
enum WindowManager {
  static func execute(command: UserCommand) async {
    guard AXIsProcessTrusted() else {
      fputs("custom-karabiner-windowlayout-server needs Accessibility permission.\n", stderr)
      return
    }

    switch command {
    case .cycleWindowLayout(let layoutCommand):
      await cycleWindowLayout(command: layoutCommand)
    }
  }

  private static func cycleWindowLayout(command: WindowLayoutCommand) async {
    switch command.target {
    case .application(let target):
      await cycleApplication(
        command: command,
        target: target)
    case .frontmost:
      cycleFrontmostWindow(command: command)
    }
  }

  private static func cycleApplication(
    command: WindowLayoutCommand,
    target: ApplicationTarget
  ) async {
    let bundleIdentifier = target.bundleIdentifier
    guard
      let applicationURL = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: bundleIdentifier)
    else {
      fputs(
        "custom-karabiner-windowlayout-server could not find \(bundleIdentifier).\n", stderr
      )
      return
    }

    let wasTargetFrontmost =
      NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleIdentifier
    if NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty {
      guard target.openIfNeeded else { return }
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = false
      configuration.addsToRecentItems = false
      NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) {
        _, error in
        if let error {
          fputs("custom-karabiner-windowlayout-server could not open the app: \(error)\n", stderr)
        }
      }
    }

    guard let application = await waitForApplication(bundleIdentifier) else {
      if !Task.isCancelled {
        fputs(
          "custom-karabiner-windowlayout-server timed out opening \(bundleIdentifier).\n",
          stderr)
      }
      return
    }
    guard !Task.isCancelled else { return }
    if target.activate {
      application.activate(options: target.activateAllWindows ? [.activateAllWindows] : [])
    }

    let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
    AXUIElementSetMessagingTimeout(applicationElement, 1.0)
    guard let frontWindow = await waitForFocusedWindow(applicationElement) else {
      if !Task.isCancelled {
        fputs(
          "custom-karabiner-windowlayout-server found no resizable focused window for \(bundleIdentifier).\n",
          stderr)
      }
      return
    }
    guard !Task.isCancelled else { return }

    apply(
      command: command,
      application: application,
      applicationElement: applicationElement,
      frontWindow: frontWindow,
      bundleIdentifier: bundleIdentifier,
      reset: target.resetCycleWhenNotFrontmost && !wasTargetFrontmost)
  }

  private static func cycleFrontmostWindow(command: WindowLayoutCommand) {
    guard let application = NSWorkspace.shared.frontmostApplication,
      let bundleIdentifier = application.bundleIdentifier
    else {
      return
    }

    let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
    AXUIElementSetMessagingTimeout(applicationElement, 1.0)
    guard let frontWindow = focusedUsableWindow(applicationElement) else {
      return
    }

    apply(
      command: command,
      application: application,
      applicationElement: applicationElement,
      frontWindow: frontWindow,
      bundleIdentifier: bundleIdentifier)
  }

  private static func apply(
    command: WindowLayoutCommand,
    application: NSRunningApplication,
    applicationElement: AXUIElement,
    frontWindow: AXUIElement,
    bundleIdentifier: String,
    reset: Bool = false
  ) {
    let windowToken = token(
      for: frontWindow,
      bundleIdentifier: bundleIdentifier,
      processIdentifier: application.processIdentifier)
    let layoutIndex = CommandCoordinator.nextCycleIndex(
      commandIdentifier: command.cycleID,
      window: windowToken,
      stepCount: command.layouts.count,
      reset: reset)
    let layout = command.layouts[layoutIndex]
    let windows: [AXUIElement]
    switch command.windowScope {
    case .focused:
      windows = [frontWindow]
    case .all:
      windows =
        [frontWindow]
        + allUsableWindows(applicationElement).filter {
          !CFEqual($0, frontWindow)
        }
    }

    guard let focusedFrame = copyFrame(frontWindow) else { return }
    for (index, window) in windows.enumerated() {
      guard let windowFrame = copyFrame(window),
        let screen = resolveScreen(
          strategy: command.screenStrategy,
          focusedFrame: focusedFrame,
          windowFrame: windowFrame)
      else {
        continue
      }
      let frame = LayoutCalculator.frame(
        layout: layout,
        screen: screen,
        screenFrame: command.screenFrame)
      let cascadeFrame = LayoutCalculator.cascadeFrame(
        frame,
        index: index,
        offset: command.cascadeOffset,
        screen: screen,
        screenFrame: command.screenFrame)
      setFrame(cascadeFrame, window: window, anchor: layout.resizeAnchor)
    }

    AXUIElementPerformAction(frontWindow, kAXRaiseAction as CFString)
    AXUIElementSetAttributeValue(
      applicationElement,
      kAXFocusedWindowAttribute as CFString,
      frontWindow)
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

  private static func waitForFocusedWindow(_ application: AXUIElement) async -> AXUIElement? {
    for _ in 0..<200 {
      if Task.isCancelled { return nil }
      if let window = focusedUsableWindow(application) { return window }
      try? await Task.sleep(for: .milliseconds(25))
    }
    return nil
  }

  private static func focusedUsableWindow(_ application: AXUIElement) -> AXUIElement? {
    guard
      let focusedWindow = copyElementAttribute(
        application,
        attribute: kAXFocusedWindowAttribute),
      isUsableWindow(focusedWindow)
    else {
      return nil
    }
    return focusedWindow
  }

  private static func allUsableWindows(_ application: AXUIElement) -> [AXUIElement] {
    copyElementArrayAttribute(application, attribute: kAXWindowsAttribute)?.filter(isUsableWindow)
      ?? []
  }

  private static func resolveScreen(
    strategy: ScreenStrategy,
    focusedFrame: CGRect,
    windowFrame: CGRect
  ) -> ScreenGeometry? {
    switch strategy {
    case .existing:
      return screenContaining(frame: focusedFrame)
    case .eachExisting:
      return screenContaining(frame: windowFrame)
    case .mouse:
      let screens = NSScreen.screens
      let mouse = NSEvent.mouseLocation
      guard let screen = screens.first(where: { $0.frame.contains(mouse) }) ?? screens.first else {
        return nil
      }
      return geometry(for: screen, allScreens: screens)
    case .primary:
      let screens = NSScreen.screens
      guard let screen = screens.first else { return nil }
      return geometry(for: screen, allScreens: screens)
    }
  }

  private static func screenContaining(frame: CGRect) -> ScreenGeometry? {
    let screens = NSScreen.screens
    let geometries = screens.compactMap { geometry(for: $0, allScreens: screens) }
    let center = CGPoint(x: frame.midX, y: frame.midY)
    if let containing = geometries.first(where: { $0.frame.contains(center) }) {
      return containing
    }
    return geometries.max {
      intersectionArea($0.frame, frame) < intersectionArea($1.frame, frame)
    } ?? geometries.first
  }

  private static func intersectionArea(_ first: CGRect, _ second: CGRect) -> CGFloat {
    let intersection = first.intersection(second)
    return intersection.isNull ? 0 : intersection.width * intersection.height
  }

  private static func geometry(for screen: NSScreen, allScreens: [NSScreen]) -> ScreenGeometry? {
    guard let primaryFrame = allScreens.first?.frame else { return nil }
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

  private static func token(
    for window: AXUIElement,
    bundleIdentifier: String,
    processIdentifier: pid_t
  ) -> AXWindowToken {
    AXWindowToken(
      bundleIdentifier: bundleIdentifier,
      processIdentifier: processIdentifier,
      element: window)
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

  private static func copyElementArrayAttribute(
    _ element: AXUIElement,
    attribute: String
  ) -> [AXUIElement]? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
      return nil
    }
    return value as? [AXUIElement]
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

  private static func setFrame(
    _ frame: CGRect,
    window: AXUIElement,
    anchor: WindowLayout.ResizeAnchor
  ) {
    setPointAttribute(window, attribute: kAXPositionAttribute, point: frame.origin)
    setSizeAttribute(window, attribute: kAXSizeAttribute, size: frame.size)
    let position = LayoutCalculator.anchoredOrigin(
      targetFrame: frame,
      actualSize: copySizeAttribute(window, attribute: kAXSizeAttribute) ?? frame.size,
      anchor: anchor)
    setPointAttribute(window, attribute: kAXPositionAttribute, point: position)
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
