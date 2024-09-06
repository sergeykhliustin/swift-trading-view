import Foundation
import TALib

public enum TALibError: Error {
    case allocationFailed
    case invalidParameter
    case inputArrayTooSmall
    case outputArrayTooSmall
    case executionFailed(String)
}

public enum MAType: UInt32 {
    case sma = 0
    case ema = 1
    case wma = 2
    case dema = 3
    case tema = 4
    case trima = 5
    case kama = 6
    case mama = 7
    case t3 = 8
}

public struct TALib {

    // MARK: - Moving Averages

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

    public static func SMA(inReal: [Double], timePeriod: Int) throws -> [Double] {
        try executeFunction(inReal.count) { (inReal, outReal, outBegIdx, outNBElement) in
            inReal.withUnsafeBufferPointer { inRealPtr in
                TA_SMA(0, Int32(inReal.count - 1), inRealPtr.baseAddress, Int32(timePeriod),
                       &outBegIdx, &outNBElement, outReal)
            }
        }
    }

    public static func EMA(inReal: [Double], timePeriod: Int) throws -> [Double] {
        try executeFunction(inReal.count) { (inReal, outReal, outBegIdx, outNBElement) in
            inReal.withUnsafeBufferPointer { inRealPtr in
                TA_EMA(0, Int32(inReal.count - 1), inRealPtr.baseAddress, Int32(timePeriod),
                       &outBegIdx, &outNBElement, outReal)
            }
        }
    }

    // MARK: - Momentum Indicators

    public static func RSI(inReal: [Double], timePeriod: Int) throws -> [Double] {
        try executeFunction(inReal.count) { (inReal, outReal, outBegIdx, outNBElement) in
            inReal.withUnsafeBufferPointer { inRealPtr in
                TA_RSI(0, Int32(inReal.count - 1), inRealPtr.baseAddress, Int32(timePeriod),
                       &outBegIdx, &outNBElement, outReal)
            }
        }
    }

    public static func MACD(inReal: [Double], fastPeriod: Int, slowPeriod: Int, signalPeriod: Int) throws -> (macd: [Double], signal: [Double], hist: [Double]) {
        let outMACD = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outSignal = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        let outHist = UnsafeMutablePointer<Double>.allocate(capacity: inReal.count)
        defer {
            outMACD.deallocate()
            outSignal.deallocate()
            outHist.deallocate()
        }

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        let retCode = inReal.withUnsafeBufferPointer { inRealPtr in
            TA_MACD(0, Int32(inReal.count - 1), inRealPtr.baseAddress,
                    Int32(fastPeriod), Int32(slowPeriod), Int32(signalPeriod),
                    &outBegIdx, &outNBElement, outMACD, outSignal, outHist)
        }

        try checkReturnCode(retCode)

        let macd = Array(UnsafeBufferPointer(start: outMACD, count: Int(outNBElement)))
        let signal = Array(UnsafeBufferPointer(start: outSignal, count: Int(outNBElement)))
        let hist = Array(UnsafeBufferPointer(start: outHist, count: Int(outNBElement)))

        return (macd, signal, hist)
    }

    // MARK: - Volatility Indicators

    public static func BBANDS(inReal: [Double], timePeriod: Int, nbDevUp: Double, nbDevDn: Double, maType: UInt32) throws -> (upperBand: [Double], middleBand: [Double], lowerBand: [Double]) {
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
                      nbDevUp, nbDevDn, TA_MAType(maType),
                      &outBegIdx, &outNBElement, outUpperBand, outMiddleBand, outLowerBand)
        }

        try checkReturnCode(retCode)

        let upperBand = Array(UnsafeBufferPointer(start: outUpperBand, count: Int(outNBElement)))
        let middleBand = Array(UnsafeBufferPointer(start: outMiddleBand, count: Int(outNBElement)))
        let lowerBand = Array(UnsafeBufferPointer(start: outLowerBand, count: Int(outNBElement)))

        return (upperBand, middleBand, lowerBand)
    }

    // MARK: - Helper Functions

    private static func executeFunction(_ capacity: Int, _ function: ([Double], UnsafeMutablePointer<Double>, inout Int32, inout Int32) -> TA_RetCode) throws -> [Double] {
        let outReal = UnsafeMutablePointer<Double>.allocate(capacity: capacity)
        defer { outReal.deallocate() }

        var outBegIdx: Int32 = 0
        var outNBElement: Int32 = 0

        let retCode = function([], outReal, &outBegIdx, &outNBElement)

        try checkReturnCode(retCode)

        // Only return the valid portion of the output
        return Array(UnsafeBufferPointer(start: outReal.advanced(by: Int(outBegIdx)), count: Int(outNBElement)))
    }

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
