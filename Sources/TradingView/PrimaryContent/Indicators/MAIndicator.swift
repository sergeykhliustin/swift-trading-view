import Foundation
import SwiftUI
import SwiftTA

extension MAType {
    var name: String {
        switch self {
        case .sma:
            return "MA"
        case .ema:
            return "EMA"
        case .wma:
            return "WMA"
        case .dema:
            return "DEMA"
        case .tema:
            return "TEMA"
        case .trima:
            return "TRIMA"
        case .kama:
            return "KAMA"
        case .mama:
            return "MAMA"
        case .t3:
            return "T3"
        }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
            .init(value: 99, color: .purple)
        ],
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        maType: MAType = .sma,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) }
    ) {
        self.periods = periods
        self.lineWidth = lineWidth
        self.maType = maType
        self.labelFont = labelFont
        self.valueFormatter = valueFormatter
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        var allVisibleValues: [Double] = candlesInfo.visibleData.map { $0.close }

        let closes = candlesInfo.data.map { $0.close }
        var values: [Int: [Double]] = [:]
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
                values[period.value] = maValues
            } catch {
                print("Error calculating MA for period \(period): \(error)")
            }
        }
        return CalculatedData(
            min: allVisibleValues.min() ?? 0,
            max: allVisibleValues.max() ?? 0,
            values: values
        )
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let values = calculatedData.values as? [Int: [Double]] else {
            return []
        }
        var texts: [Text] = []
        for period in periods {
            guard let maValues = values[period.value] else { continue }
            let beginIndex = candlesInfo.data.count - maValues.count

            var lastVisibleMAValueIndex = min(maValues.count, candlesInfo.endIndex - beginIndex) - 1
            if lastVisibleMAValueIndex < 0 {
                lastVisibleMAValueIndex = 0
            }
            let text = Text("\(self.maType.name)(\(period.value)): \(valueFormatter(maValues[lastVisibleMAValueIndex]))")
                .font(labelFont)
                .foregroundColor(period.color)
            texts.append(text)
        }
        return texts
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        // Calculate the y-scale based on the visible range
        let yScale = contextInfo.yScale
        let candleWidth = contextInfo.candleWidth
        let candleSpacing = contextInfo.candleSpacing
        let verticalPadding = contextInfo.verticalPadding
        let yBounds = contextInfo.yBounds
        let context = contextInfo.context

        guard let values = calculatedData.values as? [Int: [Double]] else {
            return
        }

        for period in periods {
            guard let maValues = values[period.value] else {
                continue
            }
            let beginIndex = candlesInfo.data.count - maValues.count

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
        }
    }
}
