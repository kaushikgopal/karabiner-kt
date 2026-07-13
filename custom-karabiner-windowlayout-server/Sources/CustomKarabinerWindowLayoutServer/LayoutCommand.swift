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

    let target: WindowTarget
    switch payload.target.type {
    case .application:
      guard let bundleIdentifier = payload.target.bundleIdentifier else {
        throw CommandError.missingBundleIdentifier
      }
      target = .application(
        ApplicationTarget(
          bundleIdentifier: bundleIdentifier,
          openIfNeeded: payload.target.openIfNeeded ?? false,
          activate: payload.target.activate ?? false,
          activateAllWindows: payload.target.activateAllWindows ?? false,
          resetCycleWhenNotFrontmost: payload.target.resetCycleWhenNotFrontmost ?? false))
    case .frontmost:
      target = .frontmost
    }

    return .cycleWindowLayout(
      WindowLayoutCommand(
        cycleID: payload.cycleID,
        target: target,
        screenStrategy: payload.screenStrategy,
        screenFrame: payload.screenFrame,
        windowScope: payload.windowScope,
        cascadeOffset: payload.cascadeOffset,
        layouts: payload.layouts))
  }

  var taskIdentifier: String {
    switch self {
    case .cycleWindowLayout(let command):
      return command.cycleID
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
  let resetCycleWhenNotFrontmost: Bool
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

  enum CodingKeys: String, CodingKey {
    case insets
    case resizeAnchor = "resize_anchor"
    case minimumWidth = "minimum_width"
    case minimumHeight = "minimum_height"
    case maximumWidth = "maximum_width"
    case maximumHeight = "maximum_height"
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
