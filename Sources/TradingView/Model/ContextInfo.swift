import Foundation
import SwiftUI

public struct ContextInfo {
    public var context: GraphicsContext
    public var contextSize: CGSize
    public var visibleBounds: CGRect
    public var candleWidth: CGFloat
    public var candleSpacing: CGFloat
    public var verticalPadding: CGFloat
    public var yBounds: (min: Double, max: Double)

    public var yScale: CGFloat

    public init(
        context: GraphicsContext,
        contextSize: CGSize,
        visibleBounds: CGRect,
        candleWidth: CGFloat,
        candleSpacing: CGFloat,
        verticalPadding: CGFloat,
        yBounds: (min: Double, max: Double)
    ) {
        self.context = context
        self.contextSize = contextSize
        self.visibleBounds = visibleBounds
        self.candleWidth = candleWidth
        self.candleSpacing = candleSpacing
        self.verticalPadding = verticalPadding
        self.yBounds = yBounds
        self.yScale = (contextSize.height - verticalPadding * 2) / CGFloat(yBounds.max - yBounds.min)
    }
}
