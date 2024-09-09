import Foundation
import SwiftUI

/// Provides context information for drawing financial charts.
///
/// This structure encapsulates all the necessary information needed to draw
/// charts, including the graphics context, size information, and scaling factors.
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct ContextInfo {
    /// The graphics context used for drawing.
    public var context: GraphicsContext

    /// The size of the entire context area.
    public var contextSize: CGSize

    /// The bounds of the visible area within the context.
    public var visibleBounds: CGRect

    /// The width of each candle in the chart.
    public var candleWidth: CGFloat

    /// The spacing between each candle in the chart.
    public var candleSpacing: CGFloat

    /// The minimum and maximum y-values in the visible range of the chart.
    public var yBounds: (min: Double, max: Double)

    /// The scale factor for converting y-values to pixel coordinates.
    public var yScale: CGFloat

    /// Initializes a new instance of `ContextInfo`.
    ///
    /// - Parameters:
    ///   - context: The graphics context used for drawing.
    ///   - contextSize: The size of the entire context area.
    ///   - visibleBounds: The bounds of the visible area within the context.
    ///   - candleWidth: The width of each candle in the chart.
    ///   - candleSpacing: The spacing between each candle in the chart.
    ///   - verticalPadding: The vertical padding at the top and bottom of the chart.
    ///   - yBounds: The minimum and maximum y-values in the visible range of the chart.
    public init(
        context: GraphicsContext,
        contextSize: CGSize,
        visibleBounds: CGRect,
        candleWidth: CGFloat,
        candleSpacing: CGFloat,
        yBounds: (min: Double, max: Double)
    ) {
        self.context = context
        self.contextSize = contextSize
        self.visibleBounds = visibleBounds
        self.candleWidth = candleWidth
        self.candleSpacing = candleSpacing
        self.yBounds = yBounds
        self.yScale = (visibleBounds.height) / CGFloat(yBounds.max - yBounds.min)
    }

    /// The total width of a candle, including its spacing.
    public var totalCandleWidth: CGFloat {
        return candleWidth + candleSpacing
    }

    /// Converts a y-value to its corresponding y-coordinate in the context.
    ///
    /// - Parameter value: The y-value to convert.
    /// - Returns: The corresponding y-coordinate in the context.
    public func yCoordinate(for value: Double) -> CGFloat {
        return CGFloat(yBounds.max - value) * yScale + visibleBounds.minY
    }

    /// Converts an x-index to its corresponding x-coordinate in the context.
    ///
    /// - Parameter index: The index of the candle.
    /// - Returns: The corresponding x-coordinate in the context.
    public func xCoordinate(for index: Int) -> CGFloat {
        return CGFloat(index) * totalCandleWidth + (candleWidth / 2)
    }
}
