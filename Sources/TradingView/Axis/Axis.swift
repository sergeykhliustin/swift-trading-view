import Foundation

/// Defines the core functionality for drawing axis on trading view.
///
/// This protocol outlines the methods required to draw
/// axis on trading view.
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public protocol Axis {
    /// Draws axis on the provided graphics context.
    ///
    /// - Parameters:
    ///   - contextInfo: Information about the graphics context and chart dimensions.
    ///   - candlesInfo: Information about the candles, including the full dataset and visible range.
    ///   - calculatedData: The data calculated by the `calculate` method.
    func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    )
}
