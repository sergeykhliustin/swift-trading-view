import Foundation

/// Represents a collection of candle data with information about the visible range.
///
/// This structure is designed to hold an array of candle data along with indices
/// that define a visible subset of that data. It's useful for managing large datasets
/// where only a portion needs to be displayed or processed at a time.
public struct CandlesInfo {
    /// The complete array of candle data.
    public var data: [CandleData]

    /// The starting index of the visible range in the `data` array.
    public var startIndex: Int

    /// The ending index (exclusive) of the visible range in the `data` array.
    public var endIndex: Int

    /// The subset of `data` that falls within the visible range.
    public var visibleData: [CandleData]

    /// Initializes a new instance of `CandlesInfo`.
    ///
    /// - Parameters:
    ///   - data: An array of `CandleData` representing the complete dataset.
    ///   - startIndex: The starting index of the visible range in the `data` array.
    ///   - endIndex: The ending index (exclusive) of the visible range in the `data` array.
    ///
    /// - Returns: A new `CandlesInfo` instance if the provided indices are valid, or `nil` otherwise.
    ///
    /// - Note: This initializer will fail (return `nil`) if:
    ///   - `startIndex` is negative
    ///   - `endIndex` is greater than the length of `data`
    ///   - The range defined by `startIndex` and `endIndex` contains fewer than two elements
    public init?(data: [CandleData], startIndex: Int, endIndex: Int) {
        self.data = data
        self.startIndex = startIndex
        self.endIndex = endIndex
        guard startIndex >= 0 && endIndex <= data.count, endIndex - startIndex > 1 else {
            return nil
        }
        self.visibleData = Array(data[startIndex..<endIndex])
    }
}
