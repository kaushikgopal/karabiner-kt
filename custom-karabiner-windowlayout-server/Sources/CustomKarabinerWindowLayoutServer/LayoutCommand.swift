import Foundation

enum UserCommand: Sendable {
  case cycleApplication(ApplicationCycleCommand)
  case cycleWindow(DirectionalCycleCommand)

  static func decode(json: Any) throws -> UserCommand {
    let data = try JSONSerialization.data(withJSONObject: json)
    let payload = try JSONDecoder().decode(Payload.self, from: data)

    guard payload.version == 2 else {
      throw CommandError.unsupportedVersion(payload.version)
    }

    switch payload.command {
    case "cycle_application_layout":
      guard let bundleIdentifier = payload.bundleIdentifier,
        let layouts = payload.layouts,
        !layouts.isEmpty
      else {
        throw CommandError.missingApplicationLayout
      }
      return .cycleApplication(
        ApplicationCycleCommand(bundleIdentifier: bundleIdentifier, layouts: layouts))

    case "cycle_frontmost_window":
      guard let direction = payload.direction else {
        throw CommandError.missingDirection
      }
      return .cycleWindow(DirectionalCycleCommand(direction: direction))

    default:
      throw CommandError.unknownCommand(payload.command)
    }
  }

  var taskIdentifier: String {
    switch self {
    case .cycleApplication(let command):
      return "app:\(command.bundleIdentifier)"
    case .cycleWindow:
      return "frontmost-window"
    }
  }

  private struct Payload: Decodable {
    let version: Int
    let command: String
    let bundleIdentifier: String?
    let layouts: [ResponsiveLayout]?
    let direction: WindowDirection?

    enum CodingKeys: String, CodingKey {
      case version
      case command
      case bundleIdentifier = "bundle_identifier"
      case layouts
      case direction
    }
  }

  private enum CommandError: Error {
    case unsupportedVersion(Int)
    case missingApplicationLayout
    case missingDirection
    case unknownCommand(String)
  }
}

struct ApplicationCycleCommand: Sendable {
  let bundleIdentifier: String
  let layouts: [ResponsiveLayout]
}

struct DirectionalCycleCommand: Sendable {
  let direction: WindowDirection
}

enum WindowDirection: String, Decodable, Sendable {
  case up
  case down
  case left
  case right

  var fractions: [CGFloat] {
    switch self {
    case .up, .down:
      return [0.5, 2.0 / 3.0]
    case .left, .right:
      return [0.5, 1.0 / 3.0, 2.0 / 3.0]
    }
  }
}

struct ResponsiveLayout: Decodable, Sendable {
  struct Dimension: Decodable, Sendable {
    let minimum: Double
    let compactRatio: Double
    let regularRatio: Double
    let maximum: Double

    enum CodingKeys: String, CodingKey {
      case minimum = "min"
      case compactRatio = "compact_ratio"
      case regularRatio = "regular_ratio"
      case maximum = "max"
    }
  }

  let compactDisplayWidth: Double
  let regularDisplayWidth: Double
  let width: Dimension
  let height: Dimension
  let compactHorizontalBias: Double
  let regularHorizontalBias: Double
  let edgePadding: Double

  enum CodingKeys: String, CodingKey {
    case compactDisplayWidth = "compact_display_width"
    case regularDisplayWidth = "regular_display_width"
    case width
    case height
    case compactHorizontalBias = "compact_horizontal_bias"
    case regularHorizontalBias = "regular_horizontal_bias"
    case edgePadding = "edge_padding"
  }
}
