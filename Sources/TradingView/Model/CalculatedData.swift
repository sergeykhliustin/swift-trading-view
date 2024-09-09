import Foundation

/// Represents the result of a technical analysis calculation.
///
/// This structure is designed to store the outcome of various technical indicators
/// or other financial calculations. It includes the minimum and maximum values
/// found in the calculation, as well as the calculated values themselves.
public struct CalculatedData {
    /// The minimum value found in the calculated data.
    ///
    /// This can be useful for scaling or normalization purposes.
    public var min: Double

    /// The maximum value found in the calculated data.
    ///
    /// This can be useful for scaling or normalization purposes.
    public var max: Double

    /// The calculated values resulting from the technical analysis.
    ///
    /// This property is of type `Any` to accommodate different types of results:
    /// - It could be a simple array of `Double` for single-line indicators.
    /// - It could be a dictionary of arrays for multi-line indicators (e.g., Bollinger Bands).
    /// - It could potentially hold more complex data structures for advanced indicators.
    ///
    /// Users of this struct should cast this property to the appropriate type
    /// based on the specific calculation performed.
    public var values: Any

    /// Initializes a new instance of `CalculatedData`.
    ///
    /// - Parameters:
    ///   - min: The minimum value in the calculated data.
    ///   - max: The maximum value in the calculated data.
    ///   - values: The calculated values. This can be of any type, typically an array or dictionary of `Double` values.
    ///
    /// - Note: It's the responsibility of the caller to ensure that `min` and `max`
    ///         accurately reflect the range of values in the `values` parameter.
    public init(min: Double, max: Double, values: Any) {
        self.min = min
        self.max = max
        self.values = values
    }
}
