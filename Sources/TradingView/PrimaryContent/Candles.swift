import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
public struct Candles: PrimaryContent {
    public var xAxisLabelFont: Font
    public var xAxisLabelColor: Color
    public var xAxisLabelInterval: Int
    public var gridLineColor: Color
    public var negativeCandleColor: Color
    public var positiveCandleColor: Color

    public init(
        xAxisLabelFont: Font = Font.system(size: 10),
        xAxisLabelColor: Color = Color.black,
        xAxisLabelInterval: Int = 10,
        gridLineColor: Color = Color.gray,
        negativeCandleColor: Color = Color.red,
        positiveCandleColor: Color = Color.green
    ) {
        self.xAxisLabelFont = xAxisLabelFont
        self.xAxisLabelColor = xAxisLabelColor
        self.xAxisLabelInterval = xAxisLabelInterval
        self.gridLineColor = gridLineColor
        self.negativeCandleColor = negativeCandleColor
        self.positiveCandleColor = positiveCandleColor
    }

    public func calculateYBounds(candlesInfo: CandlesInfo) -> (min: Double, max: Double) {
        let (minLow, maxHigh) = candlesInfo.visibleData.reduce((Double.greatestFiniteMagnitude, Double.zero)) { result, item in
            (min(result.0, item.low), max(result.1, item.high))
        }
        return (min: minLow, max: maxHigh)
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    ) {
        let context = contextInfo.context
        let candleWidth = contextInfo.candleWidth
        let candleSpacing = contextInfo.candleSpacing
        let verticalPadding = contextInfo.verticalPadding
        let yScale = contextInfo.yScale
        let yBounds = contextInfo.yBounds

        for (index, item) in candlesInfo.visibleData.enumerated() {
            let x = CGFloat(index + candlesInfo.startIndex) * (candleWidth + candleSpacing)

            // Calculate candle positions from the top
            let candleTop = verticalPadding + CGFloat(yBounds.max - item.high) * yScale
            let candleBottom = verticalPadding + CGFloat(yBounds.max - item.low) * yScale
            let bodyTop = verticalPadding + CGFloat(yBounds.max - max(item.open, item.close)) * yScale
            let bodyBottom = verticalPadding + CGFloat(yBounds.max - min(item.open, item.close)) * yScale

            // Create and draw the candle (wick)
            let candlePath = Path { path in
                path.move(to: CGPoint(x: x + candleWidth / 2, y: candleTop))
                path.addLine(to: CGPoint(x: x + candleWidth / 2, y: candleBottom))
            }
            context.stroke(
                candlePath,
                with: .color(item.open > item.close ? negativeCandleColor : positiveCandleColor),
                lineWidth: 1
            )

            // Create and draw the body
            let bodyPath = Path { path in
                path.addRect(
                    CGRect(x: x, y: bodyTop, width: candleWidth, height: bodyBottom - bodyTop)
                )
            }
            context.fill(
                bodyPath,
                with: .color(item.open > item.close ? negativeCandleColor : positiveCandleColor)
            )
        }
    }
}
