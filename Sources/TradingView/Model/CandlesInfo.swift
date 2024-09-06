import Foundation

public struct CandlesInfo {
    public var data: [CandleData]
    public var startIndex: Int
    public var endIndex: Int
    public var visibleData: [CandleData]

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
