import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct VolumeIndicator: Content {
    public var positiveCandleColor: Color
    public var negativeCandleColor: Color
    public var volumeColor: Color
    public var ma5Color: Color
    public var ma10Color: Color
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var valueFormatter: (Double) -> String
    public var yAxisLabelColor: Color

    public init(
        positiveCandleColor: Color = .green,
        negativeCandleColor: Color = .red,
        volumeColor: Color = .gray,
        ma5Color: Color = .blue,
        ma10Color: Color = .red,
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        yAxisLabelColor: Color = .black
    ) {
        self.positiveCandleColor = positiveCandleColor
        self.negativeCandleColor = negativeCandleColor
        self.volumeColor = volumeColor
        self.ma5Color = ma5Color
        self.ma10Color = ma10Color
        self.labelFont = labelFont
        self.lineWidth = lineWidth
        self.valueFormatter = valueFormatter
        self.yAxisLabelColor = yAxisLabelColor
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let volumes = candlesInfo.data.map { Double($0.volume) }

        do {
            let (ma5BeginIndex, ma5Values) = try TALib.MA(inReal: volumes, timePeriod: 5, maType: .sma)
            let (ma10BeginIndex, ma10Values) = try TALib.MA(inReal: volumes, timePeriod: 10, maType: .sma)

            let visibleVolumes = Array(volumes[candlesInfo.startIndex..<candlesInfo.endIndex])
            let visibleMA5 = Array(ma5Values[max(0, candlesInfo.startIndex - ma5BeginIndex)..<min(ma5Values.count, candlesInfo.endIndex - ma5BeginIndex)])
            let visibleMA10 = Array(ma10Values[max(0, candlesInfo.startIndex - ma10BeginIndex)..<min(ma10Values.count, candlesInfo.endIndex - ma10BeginIndex)])

            let allValues = visibleVolumes + visibleMA5 + visibleMA10
            let minValue = allValues.min() ?? 0
            let maxValue = allValues.max() ?? 0

            let yAxisLabels = calculateYAxisLabels(min: minValue, max: maxValue)

            return CalculatedData(
                min: minValue,
                max: maxValue,
                values: (
                    ma5: (beginIndex: ma5BeginIndex, values: ma5Values),
                    ma10: (beginIndex: ma10BeginIndex, values: ma10Values),
                    yAxisLabels: yAxisLabels
                )
            )
        } catch {
            print("Error calculating Volume MAs: \(error)")
            return CalculatedData(min: 0, max: 0, values: (ma5: (beginIndex: 0, values: []), ma10: (beginIndex: 0, values: []), yAxisLabels: []))
        }
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let (ma5, ma10, _) = calculatedData.values as? ((beginIndex: Int, values: [Double]), (beginIndex: Int, values: [Double]), [Double]) else {
            return []
        }

        let lastVisibleIndex = candlesInfo.endIndex - 1
        let volumeValue = candlesInfo.data[lastVisibleIndex].volume
        let ma5Value = ma5.values[safe: lastVisibleIndex - ma5.beginIndex] ?? 0
        let ma10Value = ma10.values[safe: lastVisibleIndex - ma10.beginIndex] ?? 0

        return [
            Text("Vol: \(valueFormatter(volumeValue))").font(labelFont).foregroundColor(volumeColor),
            Text("MA(5): \(valueFormatter(ma5Value))").font(labelFont).foregroundColor(ma5Color),
            Text("MA(10): \(valueFormatter(ma10Value))").font(labelFont).foregroundColor(ma10Color)
        ]
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        guard let (ma5, ma10, yAxisLabels) = calculatedData.values as? ((beginIndex: Int, values: [Double]), (beginIndex: Int, values: [Double]), [Double]) else {
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

        // Draw volume bars
        drawVolumeBars(context: context, contextInfo: contextInfo, candlesInfo: candlesInfo)

        // Draw MA lines
        drawMALine(context: context, contextInfo: contextInfo, beginIndex: ma5.beginIndex, values: ma5.values, color: ma5Color)
        drawMALine(context: context, contextInfo: contextInfo, beginIndex: ma10.beginIndex, values: ma10.values, color: ma10Color)
    }

    private func drawVolumeBars(context: GraphicsContext, contextInfo: ContextInfo, candlesInfo: CandlesInfo) {
        let barWidth = contextInfo.candleWidth

        for (index, item) in candlesInfo.visibleData.enumerated() {
            let x = contextInfo.xCoordinate(for: index + candlesInfo.startIndex)
            let y = contextInfo.yCoordinate(for: item.volume)
            let zeroY = contextInfo.yCoordinate(for: 0)

            let barRect = CGRect(
                x: x - barWidth / 2,
                y: y,
                width: barWidth,
                height: zeroY - y
            )
            let color = item.open > item.close ? negativeCandleColor : positiveCandleColor
            context.fill(Path(barRect), with: .color(color))
        }
    }

    private func drawMALine(context: GraphicsContext, contextInfo: ContextInfo, beginIndex: Int, values: [Double], color: Color) {
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
        if range <= 1000 {
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

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
