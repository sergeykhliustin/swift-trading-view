import Foundation
import SwiftUI

/// Defines the core functionality for technical analysis indicators.
///
/// This protocol outlines the methods required to calculate, display, and draw
/// technical indicators on a financial chart. Types conforming to this protocol
/// can be used as primary content in chart visualizations.
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public protocol PrimaryContent {
    /// Calculates the indicator values based on the provided candle data.
    ///
    /// This method should perform the necessary calculations to derive the
    /// indicator values from the given candle data.
    ///
    /// - Parameter candlesInfo: Information about the candles, including the full dataset and visible range.
    /// - Returns: A `CalculatedData` instance containing the results of the calculation.
    func calculate(candlesInfo: CandlesInfo) -> CalculatedData

    /// Generates legend items for the indicator.
    ///
    /// This method should create text elements to be displayed in the chart legend,
    /// typically showing current values or other relevant information about the indicator.
    ///
    /// - Parameters:
    ///   - candlesInfo: Information about the candles, including the full dataset and visible range.
    ///   - calculatedData: The data calculated by the `calculate` method.
    /// - Returns: An array of `Text` views to be displayed in the legend.
    func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text]

    /// Draws the indicator on the provided graphics context.
    ///
    /// This method is responsible for rendering the visual representation of the indicator
    /// on the chart. It should use the provided context information to properly scale and
    /// position the indicator elements.
    ///
    /// - Parameters:
    ///   - contextInfo: Information about the graphics context and chart dimensions.
    ///   - candlesInfo: Information about the candles, including the full dataset and visible range.
    ///   - calculatedData: The data calculated by the `calculate` method.
    func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    )
}
