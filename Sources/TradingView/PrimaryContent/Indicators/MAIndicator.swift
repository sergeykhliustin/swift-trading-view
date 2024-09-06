import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
public struct MAIndicator: PrimaryContent {
    public struct Period {
        public var value: Int
        public var color: Color

        public init(value: Int, color: Color) {
            self.value = value
            self.color = color
        }
    }
    public var periods: [Period]
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var maType: MAType
    public var valueFormatter: (Double) -> String

    public init(
        periods: [Period] = [
            .init(value: 7, color: .yellow),
            .init(value: 25, color: .brown),
            .init(value: 99, color: .purple),
            .init(value: 75, color: .orange),
            .init(value: 50, color: .blue),
            .init(value: 51, color: .green),
        ],
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        maType: MAType = .ema,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) }
    ) {
        self.periods = periods
        self.lineWidth = lineWidth
        self.maType = maType
        self.labelFont = labelFont
        self.valueFormatter = valueFormatter
    }

    public func calculateYBounds(candlesInfo: CandlesInfo) -> (min: Double, max: Double) {
        var allVisibleValues: [Double] = candlesInfo.visibleData.map { $0.close }

        let closes = candlesInfo.data.map { $0.close }

        for period in periods {
            do {
                let (beginIndex, maValues) = try TALib.MA(
                    inReal: closes,
                    timePeriod: period.value,
                    maType: self.maType
                )

                // Only consider MA values within the visible range
                if candlesInfo.endIndex - beginIndex > 1 {
                    let visibleMAValues = maValues[max(candlesInfo.startIndex - beginIndex, 0)..<min(candlesInfo.endIndex - beginIndex, maValues.count)]
                    allVisibleValues.append(contentsOf: visibleMAValues)
                }
            } catch {
                print("Error calculating MA for period \(period): \(error)")
            }
        }

        return (min: allVisibleValues.min() ?? 0, max: allVisibleValues.max() ?? 0)
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    ) {
        // Calculate the y-scale based on the visible range
        let yScale = contextInfo.yScale
        let candleWidth = contextInfo.candleWidth
        let candleSpacing = contextInfo.candleSpacing
        let verticalPadding = contextInfo.verticalPadding
        let yBounds = contextInfo.yBounds
        let context = contextInfo.context

        let closes = candlesInfo.data.map { $0.close }
        var texts: [Text] = []

        for period in periods {
            do {
                let (beginIndex, maValues) = try TALib.MA(
                    inReal: closes,
                    timePeriod: period.value,
                    maType: self.maType
                )

                let maPath = Path { path in
                    var firstPoint = true
                    for (index, maValue) in maValues.enumerated() {
                        let x = CGFloat(index + beginIndex) * (candleWidth + candleSpacing) + candleWidth / 2
                        let y = verticalPadding + CGFloat(yBounds.max - maValue) * yScale

                        if firstPoint {
                            path.move(to: CGPoint(x: x, y: y))
                            firstPoint = false
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }

                context.stroke(maPath, with: .color(period.color), lineWidth: lineWidth)

                var lastVisibleMAValueIndex = min(maValues.count, candlesInfo.endIndex - beginIndex) - 1
                if lastVisibleMAValueIndex < 0 {
                    lastVisibleMAValueIndex = 0
                }
                let text = Text("MA(\(period.value)): \(valueFormatter(maValues[lastVisibleMAValueIndex]))")
                    .font(labelFont)
                    .foregroundColor(period.color)
                texts.append(text)
            } catch {
                print("Error calculating MA for period \(period): \(error)")
            }
        }

        flowLayout(
            context: context,
            bounds: contextInfo.visibleBounds,
            text: texts,
            spacingX: 5,
            spacingY: 0
        )

    }
}
