import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct Candles: Content {
    public var negativeCandleColor: Color
    public var positiveCandleColor: Color

    public init(
        negativeCandleColor: Color = Color.red,
        positiveCandleColor: Color = Color.green
    ) {
        self.negativeCandleColor = negativeCandleColor
        self.positiveCandleColor = positiveCandleColor
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let (minLow, maxHigh) = candlesInfo.visibleData.reduce((Double.greatestFiniteMagnitude, Double.zero)) { result, item in
            (min(result.0, item.low), max(result.1, item.high))
        }
        return CalculatedData(
            min: minLow,
            max: maxHigh,
            values: []
        )
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        return []
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        let context = contextInfo.context
        let candleWidth = contextInfo.candleWidth

        for (index, item) in candlesInfo.visibleData.enumerated() {
            let x = contextInfo.xCoordinate(for: index + candlesInfo.startIndex)

            // Calculate candle positions from the top
            let candleTop = contextInfo.yCoordinate(for: item.high)
            let candleBottom = contextInfo.yCoordinate(for: item.low)
            let bodyTop = contextInfo.yCoordinate(for: max(item.open, item.close))
            let bodyBottom = contextInfo.yCoordinate(for: min(item.open, item.close))

            // Create and draw the candle (wick)
            let candlePath = Path { path in
                path.move(to: CGPoint(x: x, y: candleTop))
                path.addLine(to: CGPoint(x: x, y: candleBottom))
            }
            context.stroke(
                candlePath,
                with: .color(item.open > item.close ? negativeCandleColor : positiveCandleColor),
                lineWidth: 1
            )

            // Create and draw the body
            let bodyPath = Path { path in
                path.addRect(
                    CGRect(x: x - candleWidth / 2, y: bodyTop, width: candleWidth, height: bodyBottom - bodyTop)
                )
            }
            context.fill(
                bodyPath,
                with: .color(item.open > item.close ? negativeCandleColor : positiveCandleColor)
            )
        }
    }
}
