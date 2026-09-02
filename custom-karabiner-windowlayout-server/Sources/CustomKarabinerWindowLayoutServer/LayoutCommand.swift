import Foundation

enum UserCommand: Sendable {
  case cycleWindowLayout(WindowLayoutCommand)

  static func decode(json: Any) throws -> UserCommand {
    let data = try JSONSerialization.data(withJSONObject: json)
    let payload = try JSONDecoder().decode(Payload.self, from: data)

    guard payload.version == 3 else {
      throw CommandError.unsupportedVersion(payload.version)
    }
    guard payload.command == "cycle_window_layout" else {
      throw CommandError.unknownCommand(payload.command)
    }
    guard !payload.cycleID.isEmpty, !payload.layouts.isEmpty else {
      throw CommandError.missingLayout
    }
    guard payload.layouts.allSatisfy({ $0.hasValidConstraints }) else {
      throw CommandError.invalidLayoutConstraints
    }
    let timeouts = payload.timeouts ?? .default
    guard timeouts.hasValidValues else {
      throw CommandError.invalidTimeouts
    }

    let target: WindowTarget
    let legacyResetWhenNotFrontmost: Bool
    switch payload.target.type {
    case .application:
      guard let bundleIdentifier = payload.target.bundleIdentifier else {
        throw CommandError.missingBundleIdentifier
      }
      let resetWhenNotFrontmost = payload.target.resetCycleWhenNotFrontmost ?? false
      legacyResetWhenNotFrontmost = resetWhenNotFrontmost
      target = .application(
        ApplicationTarget(
          bundleIdentifier: bundleIdentifier,
          openIfNeeded: payload.target.openIfNeeded ?? false,
          activate: payload.target.activate ?? false,
          activateAllWindows: payload.target.activateAllWindows ?? false))
    case .frontmost:
      legacyResetWhenNotFrontmost = false
      target = .frontmost
    }

    let cyclePolicy: CyclePolicy
    if let payloadPolicy = payload.cyclePolicy {
      cyclePolicy = CyclePolicy(
        resetOnApplicationChange: payloadPolicy.resetOnApplicationChange ?? true,
        resetOnFocusedWindowChange: payloadPolicy.resetOnFocusedWindowChange ?? true,
        resetWhenTargetNotFrontmost:
          payloadPolicy.resetWhenTargetNotFrontmost ?? legacyResetWhenNotFrontmost)
    } else {
      cyclePolicy = CyclePolicy(
        resetOnApplicationChange: true,
        resetOnFocusedWindowChange: true,
        resetWhenTargetNotFrontmost: legacyResetWhenNotFrontmost)
    }

    return .cycleWindowLayout(
      WindowLayoutCommand(
        cycleID: payload.cycleID,
        target: target,
        screenStrategy: payload.screenStrategy,
        screenFrame: payload.screenFrame,
        windowScope: payload.windowScope,
        cascadeOffset: payload.cascadeOffset,
        layouts: payload.layouts,
        windowFilter: payload.windowFilter ?? .default,
        focusAfterLayout: payload.focusAfterLayout ?? .default,
        cyclePolicy: cyclePolicy,
        timeouts: timeouts))
  }

  var taskIdentifier: String {
    switch self {
    case .cycleWindowLayout(let command):
      return command.cycleID
    }
  }

  var cyclePolicy: CyclePolicy {
    switch self {
    case .cycleWindowLayout(let command):
      return command.cyclePolicy
    }
  }

  private struct Payload: Decodable {
    let version: Int
    let command: String
    let cycleID: String
    let target: TargetPayload
    let screenStrategy: ScreenStrategy
    let screenFrame: ScreenFrame
    let windowScope: WindowScope
    let cascadeOffset: CascadeOffset
    let layouts: [WindowLayout]
    let windowFilter: WindowFilterPolicy?
    let focusAfterLayout: FocusAfterLayoutPolicy?
    let cyclePolicy: CyclePolicyPayload?
    let timeouts: TimeoutsPolicy?

    enum CodingKeys: String, CodingKey {
      case version
      case command
      case cycleID = "cycle_id"
      case target
      case screenStrategy = "screen_strategy"
      case screenFrame = "screen_frame"
      case windowScope = "window_scope"
      case cascadeOffset = "cascade_offset"
      case layouts
      case windowFilter = "window_filter"
      case focusAfterLayout = "focus_after_layout"
      case cyclePolicy = "cycle_policy"
      case timeouts
    }
  }

  private struct TargetPayload: Decodable {
    let type: TargetType
    let bundleIdentifier: String?
    let openIfNeeded: Bool?
    let activate: Bool?
    let activateAllWindows: Bool?
    let resetCycleWhenNotFrontmost: Bool?

    enum CodingKeys: String, CodingKey {
      case type
      case bundleIdentifier = "bundle_identifier"
      case openIfNeeded = "open_if_needed"
      case activate
      case activateAllWindows = "activate_all_windows"
      case resetCycleWhenNotFrontmost = "reset_cycle_when_not_frontmost"
    }
  }

  private struct CyclePolicyPayload: Decodable {
    let resetOnApplicationChange: Bool?
    let resetOnFocusedWindowChange: Bool?
    let resetWhenTargetNotFrontmost: Bool?

    enum CodingKeys: String, CodingKey {
      case resetOnApplicationChange = "reset_on_application_change"
      case resetOnFocusedWindowChange = "reset_on_focused_window_change"
      case resetWhenTargetNotFrontmost = "reset_when_target_not_frontmost"
    }
  }

  private enum TargetType: String, Decodable {
    case application
    case frontmost
  }

  private enum CommandError: Error {
    case unsupportedVersion(Int)
    case unknownCommand(String)
    case missingBundleIdentifier
    case missingLayout
    case invalidLayoutConstraints
    case invalidTimeouts
  }
}

struct WindowLayoutCommand: Sendable {
  let cycleID: String
  let target: WindowTarget
  let screenStrategy: ScreenStrategy
  let screenFrame: ScreenFrame
  let windowScope: WindowScope
  let cascadeOffset: CascadeOffset
  let layouts: [WindowLayout]
  let windowFilter: WindowFilterPolicy
  let focusAfterLayout: FocusAfterLayoutPolicy
  let cyclePolicy: CyclePolicy
  let timeouts: TimeoutsPolicy
}

enum WindowTarget: Sendable {
  case application(ApplicationTarget)
  case frontmost
}

struct ApplicationTarget: Sendable {
  let bundleIdentifier: String
  let openIfNeeded: Bool
  let activate: Bool
  let activateAllWindows: Bool
}

/// Selects which windows are eligible for layout. Positive-size validity is
/// always enforced as an unconditional mechanism and is not governed here.
struct WindowFilterPolicy: Decodable, Sendable {
  let standardOnly: Bool
  let rejectMinimized: Bool
  let rejectFullscreen: Bool

  enum CodingKeys: String, CodingKey {
    case standardOnly = "standard_only"
    case rejectMinimized = "reject_minimized"
    case rejectFullscreen = "reject_fullscreen"
  }

  init(
    standardOnly: Bool = true,
    rejectMinimized: Bool = true,
    rejectFullscreen: Bool = true
  ) {
    self.standardOnly = standardOnly
    self.rejectMinimized = rejectMinimized
    self.rejectFullscreen = rejectFullscreen
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    standardOnly = try container.decodeIfPresent(Bool.self, forKey: .standardOnly) ?? true
    rejectMinimized = try container.decodeIfPresent(Bool.self, forKey: .rejectMinimized) ?? true
    rejectFullscreen = try container.decodeIfPresent(Bool.self, forKey: .rejectFullscreen) ?? true
  }

  static let `default` = WindowFilterPolicy()
}

/// Post-layout focus restoration. Both actions are on by default to preserve
/// the server's historical raise-then-refocus behavior.
struct FocusAfterLayoutPolicy: Decodable, Sendable {
  let raiseWindow: Bool
  let refocusWindow: Bool

  enum CodingKeys: String, CodingKey {
    case raiseWindow = "raise_window"
    case refocusWindow = "refocus_window"
  }

  init(raiseWindow: Bool = true, refocusWindow: Bool = true) {
    self.raiseWindow = raiseWindow
    self.refocusWindow = refocusWindow
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    raiseWindow = try container.decodeIfPresent(Bool.self, forKey: .raiseWindow) ?? true
    refocusWindow = try container.decodeIfPresent(Bool.self, forKey: .refocusWindow) ?? true
  }

  static let `default` = FocusAfterLayoutPolicy()
}

/// Resolved cycle-reset behavior. `resetWhenTargetNotFrontmost` is resolved at
/// decode time from `cycle_policy.reset_when_target_not_frontmost`, falling
/// back to the legacy `target.reset_cycle_when_not_frontmost` field when the
/// new key is absent.
struct CyclePolicy: Sendable {
  let resetOnApplicationChange: Bool
  let resetOnFocusedWindowChange: Bool
  let resetWhenTargetNotFrontmost: Bool

  static let `default` = CyclePolicy(
    resetOnApplicationChange: true,
    resetOnFocusedWindowChange: true,
    resetWhenTargetNotFrontmost: false)
}

/// AX messaging and wait timing. Defaults reproduce the server's historical
/// hardcoded values (1.0s AX timeout, 5s waits, 25ms polling).
struct TimeoutsPolicy: Decodable, Sendable {
  let axMessagingTimeoutSeconds: Double
  let applicationWaitTimeoutMilliseconds: Int
  let focusedWindowWaitTimeoutMilliseconds: Int
  let pollIntervalMilliseconds: Int

  enum CodingKeys: String, CodingKey {
    case axMessagingTimeoutSeconds = "ax_messaging_timeout_seconds"
    case applicationWaitTimeoutMilliseconds = "application_wait_timeout_milliseconds"
    case focusedWindowWaitTimeoutMilliseconds = "focused_window_wait_timeout_milliseconds"
    case pollIntervalMilliseconds = "poll_interval_milliseconds"
  }

  init(
    axMessagingTimeoutSeconds: Double = 1.0,
    applicationWaitTimeoutMilliseconds: Int = 5000,
    focusedWindowWaitTimeoutMilliseconds: Int = 5000,
    pollIntervalMilliseconds: Int = 25
  ) {
    self.axMessagingTimeoutSeconds = axMessagingTimeoutSeconds
    self.applicationWaitTimeoutMilliseconds = applicationWaitTimeoutMilliseconds
    self.focusedWindowWaitTimeoutMilliseconds = focusedWindowWaitTimeoutMilliseconds
    self.pollIntervalMilliseconds = pollIntervalMilliseconds
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    axMessagingTimeoutSeconds =
      try container.decodeIfPresent(Double.self, forKey: .axMessagingTimeoutSeconds) ?? 1.0
    applicationWaitTimeoutMilliseconds =
      try container.decodeIfPresent(Int.self, forKey: .applicationWaitTimeoutMilliseconds) ?? 5000
    focusedWindowWaitTimeoutMilliseconds =
      try container.decodeIfPresent(Int.self, forKey: .focusedWindowWaitTimeoutMilliseconds)
      ?? 5000
    pollIntervalMilliseconds =
      try container.decodeIfPresent(Int.self, forKey: .pollIntervalMilliseconds) ?? 25
  }

  static let `default` = TimeoutsPolicy()

  var hasValidValues: Bool {
    axMessagingTimeoutSeconds.isFinite && axMessagingTimeoutSeconds > 0
      && applicationWaitTimeoutMilliseconds >= 0
      && focusedWindowWaitTimeoutMilliseconds >= 0
      && pollIntervalMilliseconds > 0
  }
}

enum ScreenStrategy: String, Decodable, Sendable {
  case existing
  case eachExisting = "each_existing"
  case mouse
  case primary
}

enum ScreenFrame: String, Decodable, Sendable {
  case visible
  case full
}

enum WindowScope: String, Decodable, Sendable {
  case focused
  case all
}

struct CascadeOffset: Decodable, Sendable {
  let x: Double
  let y: Double
}

struct WindowLayout: Decodable, Sendable {
  struct Insets: Decodable, Sendable {
    let left: RelativeLength
    let top: RelativeLength
    let right: RelativeLength
    let bottom: RelativeLength
  }

  struct ResizeAnchor: Decodable, Sendable {
    let horizontal: HorizontalAnchor
    let vertical: VerticalAnchor
  }

  let insets: Insets
  let resizeAnchor: ResizeAnchor
  let minimumWidth: Double?
  let minimumHeight: Double?
  let maximumWidth: Double?
  let maximumHeight: Double?
  /// When true, insets/anchors are ignored and the window returns to the frame
  /// captured when its layout cycle started (layout index 0).
  let restoreOriginal: Bool

  enum CodingKeys: String, CodingKey {
    case insets
    case resizeAnchor = "resize_anchor"
    case minimumWidth = "minimum_width"
    case minimumHeight = "minimum_height"
    case maximumWidth = "maximum_width"
    case maximumHeight = "maximum_height"
    case restoreOriginal = "restore_original"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    insets = try container.decode(Insets.self, forKey: .insets)
    resizeAnchor = try container.decode(ResizeAnchor.self, forKey: .resizeAnchor)
    minimumWidth = try container.decodeIfPresent(Double.self, forKey: .minimumWidth)
    minimumHeight = try container.decodeIfPresent(Double.self, forKey: .minimumHeight)
    maximumWidth = try container.decodeIfPresent(Double.self, forKey: .maximumWidth)
    maximumHeight = try container.decodeIfPresent(Double.self, forKey: .maximumHeight)
    restoreOriginal = try container.decodeIfPresent(Bool.self, forKey: .restoreOriginal) ?? false
  }

  fileprivate var hasValidConstraints: Bool {
    let values = [minimumWidth, minimumHeight, maximumWidth, maximumHeight].compactMap { $0 }
    guard values.allSatisfy({ $0 >= 0 }) else { return false }
    if let minimumWidth, let maximumWidth, minimumWidth > maximumWidth { return false }
    if let minimumHeight, let maximumHeight, minimumHeight > maximumHeight { return false }
    return true
  }
}

struct RelativeLength: Decodable, Sendable {
  let fraction: Double
  let points: Double
}

enum HorizontalAnchor: String, Decodable, Sendable {
  case left
  case center
  case right
}

enum VerticalAnchor: String, Decodable, Sendable {
  case top
  case center
  case bottom
}
