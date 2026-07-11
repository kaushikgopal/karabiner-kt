import Foundation

struct LayoutCommand: Decodable, Sendable {
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

  let version: Int
  let command: String
  let bundleIdentifier: String
  let compactDisplayWidth: Double
  let regularDisplayWidth: Double
  let width: Dimension
  let height: Dimension
  let compactHorizontalBias: Double
  let regularHorizontalBias: Double
  let cascadeRatio: Double
  let edgePadding: Double

  enum CodingKeys: String, CodingKey {
    case version
    case command
    case bundleIdentifier = "bundle_identifier"
    case compactDisplayWidth = "compact_display_width"
    case regularDisplayWidth = "regular_display_width"
    case width
    case height
    case compactHorizontalBias = "compact_horizontal_bias"
    case regularHorizontalBias = "regular_horizontal_bias"
    case cascadeRatio = "cascade_ratio"
    case edgePadding = "edge_padding"
  }

  static func decode(json: Any) throws -> LayoutCommand {
    let data = try JSONSerialization.data(withJSONObject: json)
    return try JSONDecoder().decode(LayoutCommand.self, from: data)
  }
}
