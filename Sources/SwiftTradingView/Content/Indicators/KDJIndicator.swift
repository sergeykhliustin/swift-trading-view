import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct KDJIndicator: Content {
    public var fastKPeriod: Int
    public var slowKPeriod: Int
    public var slowDPeriod: Int
    public var kColor: Color
    public var dColor: Color
    public var jColor: Color
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var valueFormatter: (Double) -> String
    public var yAxisLabelColor: Color

    public init(
        fastKPeriod: Int = 9,
        slowKPeriod: Int = 3,
        slowDPeriod: Int = 3,
        kColor: Color = .blue,
        dColor: Color = .red,
        jColor: Color = .green,
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        yAxisLabelColor: Color = .black
    ) {
        self.fastKPeriod = fastKPeriod
        self.slowKPeriod = slowKPeriod
        self.slowDPeriod = slowDPeriod
        self.kColor = kColor
        self.dColor = dColor
        self.jColor = jColor
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
            let (beginIndex, k, d, j) = try TALib.KDJ(
                high: high,
                low: low,
                close: close,
                fastKPeriod: fastKPeriod,
                slowKPeriod: slowKPeriod,
                slowDPeriod: slowDPeriod
            )

            // Calculate min and max for the visible range
            let visibleStartIndex = max(candlesInfo.startIndex - beginIndex, 0)
            let visibleEndIndex = min(candlesInfo.endIndex - beginIndex, k.count)
            let visibleK = Array(k[visibleStartIndex..<visibleEndIndex])
            let visibleD = Array(d[visibleStartIndex..<visibleEndIndex])
            let visibleJ = Array(j[visibleStartIndex..<visibleEndIndex])
            let allVisibleValues = visibleK + visibleD + visibleJ
            let minValue = allVisibleValues.min() ?? 0
            let maxValue = allVisibleValues.max() ?? 100

            let yAxisLabels = calculateYAxisLabels(min: minValue, max: maxValue)

            return CalculatedData(
                min: minValue,
                max: maxValue,
                values: (beginIndex: beginIndex, k: k, d: d, j: j, yAxisLabels: yAxisLabels)
            )
        } catch {
            print("Error calculating KDJ: \(error)")
            return CalculatedData(min: 0, max: 100, values: (beginIndex: 0, k: [], d: [], j: [], yAxisLabels: []))
        }
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let (beginIndex, k, d, j, _) = calculatedData.values as? (Int, [Double], [Double], [Double], [Double]),
              !k.isEmpty, !d.isEmpty, !j.isEmpty else {
            return []
        }

        let lastVisibleIndex = min(k.count - 1, candlesInfo.endIndex - beginIndex - 1)
        let kValue = k[lastVisibleIndex]
        let dValue = d[lastVisibleIndex]
        let jValue = j[lastVisibleIndex]

        return [
            Text("KDJ(\(fastKPeriod),\(slowKPeriod),\(slowDPeriod))")
                .font(labelFont)
                .foregroundColor(.primary),
            Text("K: \(valueFormatter(kValue))")
                .font(labelFont)
                .foregroundColor(kColor),
            Text("D: \(valueFormatter(dValue))")
                .font(labelFont)
                .foregroundColor(dColor),
            Text("J: \(valueFormatter(jValue))")
                .font(labelFont)
                .foregroundColor(jColor)
        ]
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        guard let (beginIndex, k, d, j, yAxisLabels) = calculatedData.values as? (Int, [Double], [Double], [Double], [Double]) else {
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

        // Draw KDJ lines
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: k, color: kColor)
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: d, color: dColor)
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: j, color: jColor)
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
