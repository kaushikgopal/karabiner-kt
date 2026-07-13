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
    case .cycleApplication(let applicationCommand):
      await cycleApplication(command: applicationCommand)
    case .cycleWindow(let windowCommand):
      cycleFrontmostWindow(command: windowCommand)
    }
  }

  private static func cycleApplication(command: ApplicationCycleCommand) async {
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

    let wasTargetFrontmost =
      NSWorkspace.shared.frontmostApplication?.bundleIdentifier == command.bundleIdentifier
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    configuration.addsToRecentItems = false
    NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) {
      _, error in
      if let error {
        fputs("custom-karabiner-windowlayout-server could not open the app: \(error)\n", stderr)
      }
    }

    guard let application = await waitForApplication(command.bundleIdentifier) else {
      if !Task.isCancelled {
        fputs(
          "custom-karabiner-windowlayout-server timed out opening \(command.bundleIdentifier).\n",
          stderr)
      }
      return
    }
    guard !Task.isCancelled else { return }
    application.activate(options: [.activateAllWindows])

    let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
    AXUIElementSetMessagingTimeout(applicationElement, 1.0)
    guard let frontWindow = await waitForFocusedWindow(applicationElement) else {
      if !Task.isCancelled {
        fputs(
          "custom-karabiner-windowlayout-server found no resizable focused window for \(command.bundleIdentifier).\n",
          stderr)
      }
      return
    }
    guard !Task.isCancelled else { return }

    let windowToken = token(
      for: frontWindow,
      bundleIdentifier: command.bundleIdentifier,
      processIdentifier: application.processIdentifier)
    let layoutIndex = CommandCoordinator.nextCycleIndex(
      commandIdentifier: "app:\(command.bundleIdentifier)",
      window: windowToken,
      stepCount: command.layouts.count,
      reset: !wasTargetFrontmost)
    let frame = LayoutCalculator.frame(layout: command.layouts[layoutIndex], screen: screen)

    let windows: [AXUIElement]
    switch command.windowScope {
    case .focused:
      windows = [frontWindow]
    case .all:
      windows = [frontWindow] + allUsableWindows(applicationElement).filter {
        !CFEqual($0, frontWindow)
      }
    }
    for (index, window) in windows.enumerated() {
      let cascadeFrame = LayoutCalculator.cascadeFrame(
        frame,
        index: index,
        offset: command.cascadeOffset,
        screen: screen)
      setFrame(cascadeFrame, window: window, centerAfterResize: true)
    }
    AXUIElementPerformAction(frontWindow, kAXRaiseAction as CFString)
    AXUIElementSetAttributeValue(
      applicationElement,
      kAXFocusedWindowAttribute as CFString,
      frontWindow)
  }

  private static func cycleFrontmostWindow(command: DirectionalCycleCommand) {
    guard let application = NSWorkspace.shared.frontmostApplication,
      let bundleIdentifier = application.bundleIdentifier
    else {
      return
    }

    let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
    AXUIElementSetMessagingTimeout(applicationElement, 1.0)
    guard let frontWindow = focusedUsableWindow(applicationElement),
      let currentFrame = copyFrame(frontWindow),
      let screen = screenContaining(frame: currentFrame)
    else {
      return
    }

    let windowToken = token(
      for: frontWindow,
      bundleIdentifier: bundleIdentifier,
      processIdentifier: application.processIdentifier)
    let fractions = command.direction.fractions
    let fractionIndex = CommandCoordinator.nextCycleIndex(
      commandIdentifier: "direction:\(command.direction.rawValue)",
      window: windowToken,
      stepCount: fractions.count)
    let frame = LayoutCalculator.frame(
      direction: command.direction,
      fraction: fractions[fractionIndex],
      screen: screen)

    setFrame(frame, window: frontWindow)
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

  private static func screenUnderMouse() -> ScreenGeometry? {
    let screens = NSScreen.screens
    let mouse = NSEvent.mouseLocation
    guard let screen = screens.first(where: { $0.frame.contains(mouse) }) ?? screens.first else {
      return nil
    }
    return geometry(for: screen, allScreens: screens)
  }

  private static func screenContaining(frame: CGRect) -> ScreenGeometry? {
    let screens = NSScreen.screens
    let center = CGPoint(x: frame.midX, y: frame.midY)
    return screens.compactMap { geometry(for: $0, allScreens: screens) }
      .first(where: { $0.frame.contains(center) })
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
    centerAfterResize: Bool = false
  ) {
    setPointAttribute(window, attribute: kAXPositionAttribute, point: frame.origin)
    setSizeAttribute(window, attribute: kAXSizeAttribute, size: frame.size)
    let position = centerAfterResize
      ? LayoutCalculator.centeredOrigin(
        targetFrame: frame,
        actualSize: copySizeAttribute(window, attribute: kAXSizeAttribute) ?? frame.size)
      : frame.origin
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
