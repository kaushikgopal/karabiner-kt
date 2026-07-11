import CoreGraphics

struct ScreenGeometry: Sendable {
  let frame: CGRect
  let visibleFrame: CGRect
}

struct LayoutCalculator {
  static func frames(
    command: LayoutCommand,
    screen: ScreenGeometry,
    windowCount: Int
  ) -> [CGRect] {
    guard windowCount > 0 else { return [] }

    let scale = clamp(
      minimum: 0,
      value: (screen.visibleFrame.width - CGFloat(command.compactDisplayWidth))
        / CGFloat(command.regularDisplayWidth - command.compactDisplayWidth),
      maximum: 1)
    let widthRatio = interpolate(
      compact: command.width.compactRatio,
      regular: command.width.regularRatio,
      scale: scale)
    let heightRatio = interpolate(
      compact: command.height.compactRatio,
      regular: command.height.regularRatio,
      scale: scale)
    let horizontalBias = interpolate(
      compact: command.compactHorizontalBias,
      regular: command.regularHorizontalBias,
      scale: scale)
    let edgePadding = CGFloat(command.edgePadding)
    let visibleFrame = screen.visibleFrame

    let width = min(
      roundedClamp(
        minimum: command.width.minimum,
        value: visibleFrame.width * widthRatio,
        maximum: command.width.maximum),
      visibleFrame.width - edgePadding * 2)
    let height = min(
      roundedClamp(
        minimum: command.height.minimum,
        value: visibleFrame.height * heightRatio,
        maximum: command.height.maximum),
      visibleFrame.height - edgePadding * 2)

    let gaps = max(0, windowCount - 1)
    let availableHorizontalSpread = max(
      0,
      visibleFrame.width - width - edgePadding * 2)
    let availableVerticalSpread = max(
      0,
      visibleFrame.height - height - edgePadding * 2)
    let desiredOffsetX = (visibleFrame.width * CGFloat(command.cascadeRatio)).rounded()
    let desiredOffsetY = (visibleFrame.height * CGFloat(command.cascadeRatio)).rounded()
    let offsetX =
      gaps == 0
      ? 0
      : min(desiredOffsetX, floor(availableHorizontalSpread / CGFloat(gaps)))
    let offsetY =
      gaps == 0
      ? 0
      : min(desiredOffsetY, floor(availableVerticalSpread / CGFloat(gaps)))
    let spreadX = offsetX * CGFloat(gaps)
    let spreadY = offsetY * CGFloat(gaps)

    let centeredX = visibleFrame.minX + (visibleFrame.width - width) / 2
    let centeredY = visibleFrame.minY + (visibleFrame.height - height) / 2
    let frontX = clamp(
      minimum: visibleFrame.minX + edgePadding + spreadX,
      value: centeredX + visibleFrame.width * horizontalBias + spreadX / 2,
      maximum: visibleFrame.maxX - edgePadding - width
    ).rounded()
    let frontY = clamp(
      minimum: visibleFrame.minY + edgePadding + spreadY,
      value: centeredY + spreadY / 2,
      maximum: visibleFrame.maxY - edgePadding - height
    ).rounded()

    return (0..<windowCount).map { index in
      CGRect(
        x: frontX - offsetX * CGFloat(index),
        y: frontY - offsetY * CGFloat(index),
        width: width,
        height: height)
    }
  }

  private static func interpolate(compact: Double, regular: Double, scale: CGFloat) -> CGFloat {
    CGFloat(compact) + (CGFloat(regular) - CGFloat(compact)) * scale
  }

  private static func roundedClamp(minimum: Double, value: CGFloat, maximum: Double) -> CGFloat {
    clamp(minimum: CGFloat(minimum), value: value, maximum: CGFloat(maximum)).rounded()
  }

  private static func clamp(minimum: CGFloat, value: CGFloat, maximum: CGFloat) -> CGFloat {
    min(max(value, minimum), maximum)
  }
}
