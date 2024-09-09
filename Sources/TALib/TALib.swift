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

    // MARK: - Volatility Indicators

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
        let middleBand = Array(UnsafeBufferPointer(start: outMiddleBand, count: Int(outNBElement)))
        let lowerBand = Array(UnsafeBufferPointer(start: outLowerBand, count: Int(outNBElement)))

        return (upperBand, middleBand, lowerBand)
    }

    // MARK: - Helper Functions

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
