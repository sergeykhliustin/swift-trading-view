import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct WRIndicator: Content {
    public var timePeriod: Int
    public var color: Color
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var valueFormatter: (Double) -> String
    public var yAxisLabelColor: Color

    public init(
        timePeriod: Int = 14,
        color: Color = .yellow,
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        yAxisLabelColor: Color = .black
    ) {
        self.timePeriod = timePeriod
        self.color = color
        self.labelFont = labelFont
        self.lineWidth = lineWidth
        self.valueFormatter = valueFormatter
        self.yAxisLabelColor = yAxisLabelColor
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let high = candlesInfo.data.map { $0.high }
        let low = candlesInfo.data.map { $0.low }
        let close = candlesInfo.data.map { $0.close }

        do {
            let (beginIndex, wrValues) = try TALib.WR(
                high: high,
                low: low,
                close: close,
                timePeriod: timePeriod
            )

            // Calculate min and max for the visible range
            let visibleStartIndex = max(candlesInfo.startIndex - beginIndex, 0)
            let visibleEndIndex = min(candlesInfo.endIndex - beginIndex, wrValues.count)
            let visibleWR = Array(wrValues[visibleStartIndex..<visibleEndIndex])

            let minValue = visibleWR.min() ?? -100
            let maxValue = visibleWR.max() ?? 0

            let yAxisLabels = calculateYAxisLabels(min: minValue, max: maxValue)

            return CalculatedData(
                min: minValue,
                max: maxValue,
                values: (beginIndex: beginIndex, wr: wrValues, yAxisLabels: yAxisLabels)
            )
        } catch {
            print("Error calculating WR: \(error)")
            return CalculatedData(min: -100, max: 0, values: (beginIndex: 0, wr: [], yAxisLabels: []))
        }
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let (beginIndex, wr, _) = calculatedData.values as? (Int, [Double], [Double]),
              !wr.isEmpty else {
            return []
        }

        let lastVisibleIndex = min(wr.count - 1, candlesInfo.endIndex - beginIndex - 1)
        let wrValue = wr[lastVisibleIndex]

        return [
            Text("Wm %R(\(timePeriod)): \(valueFormatter(wrValue))")
                .font(labelFont)
                .foregroundColor(color)
        ]
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        guard let (beginIndex, wr, yAxisLabels) = calculatedData.values as? (Int, [Double], [Double]) else {
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

        // Draw WR line
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: wr, color: color)
    }

    private func drawLine(context: GraphicsContext, contextInfo: ContextInfo, beginIndex: Int, values: [Double], color: Color) {
        let linePath = Path { path in
            var firstPoint = true
            for (index, value) in values.enumerated() {
                let x = contextInfo.xCoordinate(for: index + beginIndex)
                let y = contextInfo.yCoordinate(for: value)

                if firstPoint {
                    path.move(to: CGPoint(x: x, y: y))
                    firstPoint = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }

        context.stroke(linePath, with: .color(color), lineWidth: lineWidth)
    }

    private func calculateYAxisLabels(min: Double, max: Double) -> [Double] {
        let range = max - min
        let step = calculateStep(range)

        var labels: [Double] = []
        var current = (min / step).rounded(.down) * step
        while current <= max {
            if current >= min {
                labels.append(current)
            }
            current += step
        }

        // Ensure we have at least 2 labels
        while labels.count < 2 {
            if labels.first! > min {
                labels.insert(labels.first! - step, at: 0)
            } else {
                labels.append(labels.last! + step)
            }
        }

        return labels
    }

    private func calculateStep(_ range: Double) -> Double {
        let rough = range / 4 // Aim for roughly 4 steps
        let magnitude = pow(10, floor(log10(rough)))
        let steps = [1.0, 2.0, 5.0, 10.0]
        return steps.lazy
            .map { $0 * magnitude }
            .first { $0 >= rough } ?? magnitude * 10
    }
}
