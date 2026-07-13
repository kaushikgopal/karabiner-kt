import CoreGraphics

struct ScreenGeometry: Sendable {
  let frame: CGRect
  let visibleFrame: CGRect
}

struct LayoutCalculator {
  static func cascadeFrame(
    _ frame: CGRect,
    index: Int,
    offset: CGFloat,
    screen: ScreenGeometry
  ) -> CGRect {
    let visibleFrame = screen.visibleFrame
    let distance = CGFloat(index) * offset
    let x = clamp(
      minimum: visibleFrame.minX,
      value: frame.minX + distance,
      maximum: visibleFrame.maxX - frame.width)
    let y = clamp(
      minimum: visibleFrame.minY,
      value: frame.minY + distance,
      maximum: visibleFrame.maxY - frame.height)
    return CGRect(origin: CGPoint(x: x.rounded(), y: y.rounded()), size: frame.size)
  }

  static func centeredOrigin(targetFrame: CGRect, actualSize: CGSize) -> CGPoint {
    CGPoint(
      x: (targetFrame.midX - actualSize.width / 2).rounded(),
      y: (targetFrame.midY - actualSize.height / 2).rounded())
  }

  static func frame(layout: ResponsiveLayout, screen: ScreenGeometry) -> CGRect {
    let scale = clamp(
      minimum: 0,
      value: (screen.visibleFrame.width - CGFloat(layout.compactDisplayWidth))
        / CGFloat(layout.regularDisplayWidth - layout.compactDisplayWidth),
      maximum: 1)
    let widthRatio = interpolate(
      compact: layout.width.compactRatio,
      regular: layout.width.regularRatio,
      scale: scale)
    let heightRatio = interpolate(
      compact: layout.height.compactRatio,
      regular: layout.height.regularRatio,
      scale: scale)
    let horizontalBias = interpolate(
      compact: layout.compactHorizontalBias,
      regular: layout.regularHorizontalBias,
      scale: scale)
    let edgePadding = CGFloat(layout.edgePadding)
    let visibleFrame = screen.visibleFrame

    let width = min(
      roundedClamp(
        minimum: layout.width.minimum,
        value: visibleFrame.width * widthRatio,
        maximum: layout.width.maximum),
      visibleFrame.width - edgePadding * 2)
    let height = min(
      roundedClamp(
        minimum: layout.height.minimum,
        value: visibleFrame.height * heightRatio,
        maximum: layout.height.maximum),
      visibleFrame.height - edgePadding * 2)
    let centeredX = visibleFrame.minX + (visibleFrame.width - width) / 2
    let centeredY = visibleFrame.minY + (visibleFrame.height - height) / 2
    let x = clamp(
      minimum: visibleFrame.minX + edgePadding,
      value: centeredX + visibleFrame.width * horizontalBias,
      maximum: visibleFrame.maxX - edgePadding - width
    ).rounded()
    let y = clamp(
      minimum: visibleFrame.minY + edgePadding,
      value: centeredY,
      maximum: visibleFrame.maxY - edgePadding - height
    ).rounded()

    return CGRect(x: x, y: y, width: width, height: height)
  }

  static func frame(
    direction: WindowDirection,
    fraction: CGFloat,
    screen: ScreenGeometry
  ) -> CGRect {
    let visibleFrame = screen.visibleFrame

    switch direction {
    case .up:
      let height = (visibleFrame.height * fraction).rounded()
      return CGRect(
        x: visibleFrame.minX,
        y: visibleFrame.minY,
        width: visibleFrame.width,
        height: height)

    case .down:
      let height = (visibleFrame.height * fraction).rounded()
      return CGRect(
        x: visibleFrame.minX,
        y: visibleFrame.maxY - height,
        width: visibleFrame.width,
        height: height)

    case .left:
      let width = (visibleFrame.width * fraction).rounded()
      return CGRect(
        x: visibleFrame.minX,
        y: visibleFrame.minY,
        width: width,
        height: visibleFrame.height)

    case .right:
      let width = (visibleFrame.width * fraction).rounded()
      return CGRect(
        x: visibleFrame.maxX - width,
        y: visibleFrame.minY,
        width: width,
        height: visibleFrame.height)
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
