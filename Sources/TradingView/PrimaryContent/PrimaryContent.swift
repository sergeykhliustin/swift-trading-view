import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public protocol PrimaryContent {
    func calculate(
        candlesInfo: CandlesInfo
    ) -> CalculatedData

    func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text]

    func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    )
}
