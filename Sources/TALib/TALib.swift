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

    /// Calculates the Relative Strength Index (RSI) for a given set of data.
    ///
    /// - Parameters:
    ///   - inReal: An array of Double values representing the input data (typically closing prices).
    ///   - timePeriod: The number of periods to use in the RSI calculation. Typical values are 14, 9, or 25.
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - values: An array of Double values representing the calculated RSI.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func RSI(inReal: [Double], timePeriod: Int) throws -> (beginIndex: Int, values: [Double]) {
        guard inReal.count > timePeriod else {
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
            TA_RSI(startIdx, endIdx, inRealPtr.baseAddress, optInTimePeriod,
                   &outBegIdx, &outNBElement, outReal)
        }

        try checkReturnCode(retCode)

        // Only return the valid portion of the output
        return (Int(outBegIdx), Array(UnsafeBufferPointer(start: outReal, count: Int(outNBElement))))
    }

    /// Calculates the Moving Average Convergence/Divergence (MACD) for a given set of data.
    ///
    /// - Parameters:
    ///   - inReal: An array of Double values representing the input data (typically closing prices).
    ///   - fastPeriod: The number of periods for the fast EMA. Default is 12.
    ///   - slowPeriod: The number of periods for the slow EMA. Default is 26.
    ///   - signalPeriod: The number of periods for the signal line EMA. Default is 9.
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - macdLine: An array of Double values representing the MACD line.
    ///   - signalLine: An array of Double values representing the signal line.
    ///   - histogram: An array of Double values representing the MACD histogram.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func MACD(
        inReal: [Double],
        fastPeriod: Int,
        slowPeriod: Int,
        signalPeriod: Int
    ) throws -> (beginIndex: Int, macdLine: [Double], signalLine: [Double], histogram: [Double]) {
        guard inReal.count >= max(fastPeriod, slowPeriod, signalPeriod) else {
            throw TALibError.inputArrayTooSmall
        }

        let startIdx: Int32 = 0
        let endIdx: Int32 = Int32(inReal.count - 1)
        let optInFastPeriod: Int32 = Int32(fastPeriod)
        let optInSlowPeriod: Int32 = Int32(slowPeriod)
        let optInSignalPeriod: Int32 = Int32(signalPeriod)

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        // Allocate memory for the worst case scenario (same size as input)
        let outMACD = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outMACDSignal = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outMACDHist = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        defer {
            outMACD.deallocate()
            outMACDSignal.deallocate()
            outMACDHist.deallocate()
        }

        let retCode = inReal.withUnsafeBufferPointer { inRealPtr in
            TA_MACD(startIdx, endIdx, inRealPtr.baseAddress,
                    optInFastPeriod, optInSlowPeriod, optInSignalPeriod,
                    &outBegIdx, &outNBElement,
                    outMACD, outMACDSignal, outMACDHist)
        }

        try checkReturnCode(retCode)

        // Only return the valid portion of the output
        let macdLine = Array(UnsafeBufferPointer(start: outMACD, count: Int(outNBElement)))
        let signalLine = Array(UnsafeBufferPointer(start: outMACDSignal, count: Int(outNBElement)))
        let histogram = Array(UnsafeBufferPointer(start: outMACDHist, count: Int(outNBElement)))

        return (Int(outBegIdx), macdLine, signalLine, histogram)
    }

    /// Calculates the KDJ (Stochastic Oscillator) indicator for a given set of data.
    ///
    /// - Parameters:
    ///   - high: An array of Double values representing the high prices.
    ///   - low: An array of Double values representing the low prices.
    ///   - close: An array of Double values representing the closing prices.
    ///   - fastKPeriod: The time period for the %K line. Default is 9.
    ///   - slowKPeriod: The time period for the slow %K line. Default is 3.
    ///   - slowDPeriod: The time period for the %D line. Default is 3.
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - k: An array of Double values representing the %K line.
    ///   - d: An array of Double values representing the %D line.
    ///   - j: An array of Double values representing the %J line.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func KDJ(
        high: [Double],
        low: [Double],
        close: [Double],
        fastKPeriod: Int,
        slowKPeriod: Int,
        slowDPeriod: Int
    ) throws -> (beginIndex: Int, k: [Double], d: [Double], j: [Double]) {
        guard high.count == low.count, high.count == close.count, !high.isEmpty else {
            throw TALibError.invalidParameter
        }

        // Calculate Stochastic Oscillator (%K and %D)
        let (stochBeginIndex, _, slowK, slowD) = try STOCH(
            high: high,
            low: low,
            close: close,
            fastKPeriod: fastKPeriod,
            slowKPeriod: slowKPeriod,
            slowDPeriod: slowDPeriod
        )

        // Calculate %J
        var j = [Double]()
        for i in 0..<slowK.count {
            let jValue = 3 * slowK[i] - 2 * slowD[i]
            j.append(jValue)
        }

        return (stochBeginIndex, slowK, slowD, j)
    }

    /// Calculates the Stochastic Oscillator for a given set of data.
    ///
    /// - Parameters:
    ///   - high: An array of Double values representing the high prices.
    ///   - low: An array of Double values representing the low prices.
    ///   - close: An array of Double values representing the closing prices.
    ///   - fastKPeriod: The time period for the %K line. Default is 5.
    ///   - slowKPeriod: The time period for the slow %K line. Default is 3.
    ///   - slowDPeriod: The time period for the %D line. Default is 3.
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - fastK: An array of Double values representing the fast %K line.
    ///   - slowK: An array of Double values representing the slow %K line.
    ///   - slowD: An array of Double values representing the %D line.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func STOCH(
        high: [Double],
        low: [Double],
        close: [Double],
        fastKPeriod: Int,
        slowKPeriod: Int,
        slowDPeriod: Int
    ) throws -> (beginIndex: Int, fastK: [Double], slowK: [Double], slowD: [Double]) {
        guard high.count == low.count, high.count == close.count, !high.isEmpty else {
            throw TALibError.invalidParameter
        }

        let dataCount = high.count
        let startIdx: Int32 = 0
        let endIdx: Int32 = Int32(dataCount - 1)

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        let outSlowK = UnsafeMutablePointer<Double>.allocate(capacity: dataCount)
        let outSlowD = UnsafeMutablePointer<Double>.allocate(capacity: dataCount)
        defer {
            outSlowK.deallocate()
            outSlowD.deallocate()
        }

        let retCode = high.withUnsafeBufferPointer { highPtr in
            low.withUnsafeBufferPointer { lowPtr in
                close.withUnsafeBufferPointer { closePtr in
                    TA_STOCH(startIdx, endIdx,
                             highPtr.baseAddress, lowPtr.baseAddress, closePtr.baseAddress,
                             Int32(fastKPeriod), Int32(slowKPeriod), TA_MAType(0),
                             Int32(slowDPeriod), TA_MAType(0),
                             &outBegIdx, &outNBElement,
                             outSlowK, outSlowD)
                }
            }
        }

        try checkReturnCode(retCode)

        let slowK = Array(UnsafeBufferPointer(start: outSlowK, count: Int(outNBElement)))
        let slowD = Array(UnsafeBufferPointer(start: outSlowD, count: Int(outNBElement)))

        // Calculate fast %K
        var fastK = [Double]()
        for i in 0..<Int(outNBElement) {
            let highestHigh = high[Int(outBegIdx)+i-fastKPeriod+1...Int(outBegIdx)+i].max() ?? 0
            let lowestLow = low[Int(outBegIdx)+i-fastKPeriod+1...Int(outBegIdx)+i].min() ?? 0
            let currentClose = close[Int(outBegIdx)+i]
            let fastKValue = (currentClose - lowestLow) / (highestHigh - lowestLow) * 100
            fastK.append(fastKValue)
        }

        return (Int(outBegIdx), fastK, slowK, slowD)
    }

    /// Calculates the Williams %R (WR) indicator for a given set of data.
    ///
    /// - Parameters:
    ///   - high: An array of Double values representing the high prices.
    ///   - low: An array of Double values representing the low prices.
    ///   - close: An array of Double values representing the closing prices.
    ///   - timePeriod: The number of periods to use for the calculation. Default is 14.
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - values: An array of Double values representing the calculated Williams %R.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func WR(
        high: [Double],
        low: [Double],
        close: [Double],
        timePeriod: Int = 14
    ) throws -> (beginIndex: Int, values: [Double]) {
        guard high.count == low.count, high.count == close.count, !high.isEmpty else {
            throw TALibError.invalidParameter
        }

        guard high.count >= timePeriod else {
            throw TALibError.inputArrayTooSmall
        }

        let dataCount = high.count
        let startIdx: Int32 = 0
        let endIdx: Int32 = Int32(dataCount - 1)
        let optInTimePeriod: Int32 = Int32(timePeriod)

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        let outReal = UnsafeMutablePointer<Double>.allocate(capacity: dataCount)
        defer { outReal.deallocate() }

        let retCode = high.withUnsafeBufferPointer { highPtr in
            low.withUnsafeBufferPointer { lowPtr in
                close.withUnsafeBufferPointer { closePtr in
                    TA_WILLR(startIdx, endIdx,
                             highPtr.baseAddress, lowPtr.baseAddress, closePtr.baseAddress,
                             optInTimePeriod,
                             &outBegIdx, &outNBElement, outReal)
                }
            }
        }

        try checkReturnCode(retCode)

        let wrValues = Array(UnsafeBufferPointer(start: outReal, count: Int(outNBElement)))

        return (Int(outBegIdx), wrValues)
    }
    
    /// Calculates the Stochastic RSI (StochRSI) indicator.
    ///
    /// - Parameters:
    ///   - inReal: An array of Double values representing the input data (typically closing prices).
    ///   - timePeriod: The number of periods for RSI calculation. Default is 14. (2 to 100000)
    ///   - fastKPeriod: The number of periods for building the Fast-K line. Default is 3. (1 to 100000)
    ///   - fastDPeriod: The number of periods for smoothing the Fast-D line. Default is 3. (1 to 100000)
    ///   - fastDMAType: The type of Moving Average for Fast-D. Default is .sma.
    /// - Returns: A tuple containing:
    ///   - beginIndex: The index in the original array where the output begins.
    ///   - fastK: An array of Double values representing the StochRSI %K line.
    ///   - fastD: An array of Double values representing the StochRSI %D line.
    /// - Throws: `TALibError` if the calculation fails or if input parameters are invalid.
    public static func StochRSI(
        inReal: [Double],
        timePeriod: Int = 14,
        fastKPeriod: Int = 3,
        fastDPeriod: Int = 3,
        fastDMAType: MAType = .sma
    ) throws -> (beginIndex: Int, fastK: [Double], fastD: [Double]) {
        guard inReal.count >= timePeriod else {
            throw TALibError.inputArrayTooSmall
        }

        let startIdx: Int32 = 0
        let endIdx: Int32 = Int32(inReal.count - 1)

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        let outFastK = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outFastD = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        defer {
            outFastK.deallocate()
            outFastD.deallocate()
        }

        let retCode = inReal.withUnsafeBufferPointer { inRealPtr in
            TA_STOCHRSI(startIdx, endIdx, inRealPtr.baseAddress,
                        Int32(timePeriod),
                        Int32(fastKPeriod),
                        Int32(fastDPeriod),
                        TA_MAType(fastDMAType.rawValue),
                        &outBegIdx, &outNBElement,
                        outFastK, outFastD)
        }

        try checkReturnCode(retCode)

        let fastK = Array(UnsafeBufferPointer(start: outFastK, count: Int(outNBElement)))
        let fastD = Array(UnsafeBufferPointer(start: outFastD, count: Int(outNBElement)))

        return (Int(outBegIdx), fastK, fastD)
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
