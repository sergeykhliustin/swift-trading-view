import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct RSIIndicator: Content {
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
    public var valueFormatter: (Double) -> String
    public var yAxisLabelColor: Color

    public init(
        periods: [Period] = [
            .init(value: 6, color: .yellow),
            .init(value: 12, color: .pink),
            .init(value: 24, color: .purple)
        ],
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        yAxisLabelColor: Color = .black
    ) {
        self.periods = periods
        self.labelFont = labelFont
        self.lineWidth = lineWidth
        self.valueFormatter = valueFormatter
        self.yAxisLabelColor = yAxisLabelColor
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let closes = candlesInfo.data.map { $0.close }
        var visibleRSIValues: [Double] = []
        var rsiData: [Int: (beginIndex: Int, values: [Double])] = [:]

        for period in periods {
            do {
                let (beginIndex, rsiValues) = try TALib.RSI(
                    inReal: closes,
                    timePeriod: period.value
                )
                rsiData[period.value] = (beginIndex: beginIndex, values: rsiValues)

                // Only consider RSI values within the visible range
                if candlesInfo.endIndex - beginIndex > 0 {
                    let visibleStartIndex = max(candlesInfo.startIndex - beginIndex, 0)
                    let visibleEndIndex = min(candlesInfo.endIndex - beginIndex, rsiValues.count)
                    visibleRSIValues.append(contentsOf: rsiValues[visibleStartIndex..<visibleEndIndex])
                }
            } catch {
                print("Error calculating RSI for period \(period.value): \(error)")
            }
        }

        let minRSI = visibleRSIValues.min() ?? 0
        let maxRSI = visibleRSIValues.max() ?? 100

        // Calculate y-axis labels based on visible range
        let yAxisLabels = calculateYAxisLabels(min: minRSI, max: maxRSI)

        return CalculatedData(
            min: 0, // RSI is always between 0 and 100
            max: 100,
            values: (rsiData: rsiData, yAxisLabels: yAxisLabels)
        )
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let (rsiData, _) = calculatedData.values as? ([Int: (beginIndex: Int, values: [Double])], [Double]) else {
            return []
        }

        return periods.compactMap { period in
            guard let (beginIndex, rsiValues) = rsiData[period.value],
                  !rsiValues.isEmpty else {
                return nil
            }

            let lastVisibleIndex = min(rsiValues.count, candlesInfo.endIndex - beginIndex) - 1
            let lastRSIValue = rsiValues[lastVisibleIndex]

            return Text("RSI(\(period.value)): \(valueFormatter(lastRSIValue))")
                .font(labelFont)
                .foregroundColor(period.color)
        }
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        guard let (rsiData, yAxisLabels) = calculatedData.values as? ([Int: (beginIndex: Int, values: [Double])], [Double]) else {
            return
        }

        let context = contextInfo.context

        // Draw y-axis labels
        for label in yAxisLabels {
            let y = contextInfo.yCoordinate(for: label)
            let labelText = Text(valueFormatter(label))
                .font(labelFont)
                .foregroundColor(yAxisLabelColor)

            let resolvedText = context.resolve(labelText)
            let textSize = resolvedText.measure(in: contextInfo.contextSize)

            context.draw(labelText, at: CGPoint(x: contextInfo.visibleBounds.maxX - textSize.width / 2, y: y - textSize.height / 2))
        }

        // Draw RSI lines
        for period in periods {
            guard let (beginIndex, rsiValues) = rsiData[period.value] else {
                continue
            }

            let rsiPath = Path { path in
                var firstPoint = true
                for (index, rsiValue) in rsiValues.enumerated() {
                    let x = contextInfo.xCoordinate(for: index + beginIndex)
                    let y = contextInfo.yCoordinate(for: rsiValue)

                    if firstPoint {
                        path.move(to: CGPoint(x: x, y: y))
                        firstPoint = false
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }

            context.stroke(rsiPath, with: .color(period.color), lineWidth: lineWidth)
        }
    }

    private func calculateYAxisLabels(min: Double, max: Double) -> [Double] {
        let range = max - min
        if range <= 30 {
            // If the range is small, just return one label in the middle
            return [(min + max) / 2].map { $0.rounded() }
        } else {
            // Otherwise, return two labels
            let lowerLabel = (min + range * 0.25).rounded()
            let upperLabel = (max - range * 0.25).rounded()
            return [lowerLabel, upperLabel]
        }
    }
}
