import Foundation
import TALib

/// Represents errors that can occur when using the TALib wrapper.
public enum TALibError: Error {
    /// Indicates a memory allocation failure.
    case allocationFailed
    /// Indicates that an invalid parameter was provided to a function.
    case invalidParameter
    /// Indicates that the input array is too small for the requested operation.
    case inputArrayTooSmall
    /// Indicates that the output array is too small to hold the result.
    case outputArrayTooSmall
    /// Indicates that the TALib function execution failed with a specific error message.
    case executionFailed(String)
}

/// Represents the types of Moving Averages available in TALib.
public enum MAType: UInt32 {
    /// Simple Moving Average
    case sma = 0
    /// Exponential Moving Average
    case ema = 1
    /// Weighted Moving Average
    case wma = 2
    /// Double Exponential Moving Average
    case dema = 3
    /// Triple Exponential Moving Average
    case tema = 4
    /// Triangular Moving Average
    case trima = 5
    /// Kaufman Adaptive Moving Average
    case kama = 6
    /// MESA Adaptive Moving Average
    case mama = 7
    /// Triple Exponential Moving Average (T3)
    case t3 = 8
}

/// A Swift wrapper for the TALib (Technical Analysis Library) functions.
public struct TALib {

    // MARK: - Moving Averages

    /// Calculates the Moving Average for a given set of data.
    ///
    /// - Parameters:
    ///   - inReal: An array of Double values representing the input data.
    ///   - timePeriod: The number of periods to use in the calculation.
    ///   - maType: The type of Moving Average to calculate (e.g., SMA, EMA).
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - values: An array of Double values representing the calculated Moving Average.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func MA(inReal: [Double], timePeriod: Int, maType: MAType) throws -> (beginIndex: Int, values: [Double]) {
        guard inReal.count >= timePeriod else {
            throw TALibError.inputArrayTooSmall
        }

        let startIdx: Int32 = 0
        let endIdx: Int32 = Int32(inReal.count - 1)
        let optInTimePeriod: Int32 = Int32(timePeriod)

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        // Allocate memory for the worst case scenario (same size as input)
        let outReal = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        defer { outReal.deallocate() }

        let retCode = inReal.withUnsafeBufferPointer { inRealPtr in
            TA_MA(startIdx, endIdx, inRealPtr.baseAddress, optInTimePeriod,
                  TA_MAType(maType.rawValue),
                  &outBegIdx, &outNBElement, outReal)
        }

        try checkReturnCode(retCode)

        // Only return the valid portion of the output
        return (Int(outBegIdx), Array(UnsafeBufferPointer(start: outReal, count: Int(outNBElement))))
    }

    // MARK: - Volatility Indicators

    /// Calculates Bollinger Bands for a given set of data.
    ///
    /// - Parameters:
    ///   - inReal: An array of Double values representing the input data.
    ///   - timePeriod: The number of periods to use in the calculation.
    ///   - nbDevUp: The number of standard deviations to add for the upper band.
    ///   - nbDevDn: The number of standard deviations to subtract for the lower band.
    ///   - maType: The type of Moving Average to use for the middle band.
    /// - Returns: A tuple containing three arrays of Double values representing:
    ///   - upperBand: The upper Bollinger Band.
    ///   - middleBand: The middle Bollinger Band (Moving Average).
    ///   - lowerBand: The lower Bollinger Band.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func BBANDS(inReal: [Double], timePeriod: Int, nbDevUp: Double, nbDevDn: Double, maType: MAType) throws -> (upperBand: [Double], middleBand: [Double], lowerBand: [Double]) {
        let outUpperBand = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outMiddleBand = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outLowerBand = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        defer {
            outUpperBand.deallocate()
            outMiddleBand.deallocate()
            outLowerBand.deallocate()
        }

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        let retCode = inReal.withUnsafeBufferPointer { inRealPtr in
            TA_BBANDS(0, Int32(inReal.count - 1), inRealPtr.baseAddress, Int32(timePeriod),
                      nbDevUp, nbDevDn, TA_MAType(maType.rawValue),
                      &outBegIdx, &outNBElement, outUpperBand, outMiddleBand, outLowerBand)
        }

        try checkReturnCode(retCode)

        let upperBand = Array(UnsafeBufferPointer(start: outUpperBand, count: Int(outNBElement)))
        let middleBand = Array(UnsafeMutableBufferPointer(start: outMiddleBand, count: Int(outNBElement)))
        let lowerBand = Array(UnsafeMutableBufferPointer(start: outLowerBand, count: Int(outNBElement)))

        return (upperBand, middleBand, lowerBand)
    }

    // MARK: - Helper Functions

    /// Checks the return code from TALib functions and throws appropriate errors.
    ///
    /// - Parameter code: The TA_RetCode returned by a TALib function.
    /// - Throws: `TALibError` based on the input return code.
    private static func checkReturnCode(_ code: TA_RetCode) throws {
        switch code {
        case TA_SUCCESS:
            return
        case TA_OUT_OF_RANGE_START_INDEX,
             TA_OUT_OF_RANGE_END_INDEX,
             TA_INPUT_NOT_ALL_INITIALIZE,
             TA_BAD_PARAM:
            throw TALibError.invalidParameter
        case TA_ALLOC_ERR:
            throw TALibError.allocationFailed
        default:
            throw TALibError.executionFailed("Unknown error: \(code)")
        }
    }
}
