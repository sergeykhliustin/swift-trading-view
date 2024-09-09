import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct MACDIndicator: Content {
    public var shortPeriod: Int
    public var longPeriod: Int
    public var maPeriod: Int
    public var macdColor: Color
    public var signalColor: Color
    public var positiveColor: Color
    public var negativeColor: Color
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var valueFormatter: (Double) -> String
    public var yAxisLabelColor: Color

    public init(
        shortPeriod: Int = 12,
        longPeriod: Int = 26,
        maPeriod: Int = 9,
        macdColor: Color = .blue,
        signalColor: Color = .red,
        positiveColor: Color = .green,
        negativeColor: Color = .red,
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        yAxisLabelColor: Color = .black
    ) {
        self.shortPeriod = shortPeriod
        self.longPeriod = longPeriod
        self.maPeriod = maPeriod
        self.macdColor = macdColor
        self.signalColor = signalColor
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self.labelFont = labelFont
        self.lineWidth = lineWidth
        self.valueFormatter = valueFormatter
        self.yAxisLabelColor = yAxisLabelColor
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let closes = candlesInfo.data.map { $0.close }
        do {
            let (beginIndex, macdLine, signalLine, histogram) = try TALib.MACD(
                inReal: closes,
                fastPeriod: shortPeriod,
                slowPeriod: longPeriod,
                signalPeriod: maPeriod
            )

            let visibleStartIndex = max(candlesInfo.startIndex - beginIndex, 0)
            let visibleEndIndex = min(candlesInfo.endIndex - beginIndex, macdLine.count)

            guard visibleStartIndex < visibleEndIndex else {
                return CalculatedData(min: 0, max: 0, values: (beginIndex: 0, macdLine: [], signalLine: [], histogram: [], yAxisLabels: []))
            }

            let visibleMacdLine = Array(macdLine[visibleStartIndex..<visibleEndIndex])
            let visibleSignalLine = Array(signalLine[visibleStartIndex..<visibleEndIndex])
            let visibleHistogram = Array(histogram[visibleStartIndex..<visibleEndIndex])

            let allValues = visibleMacdLine + visibleSignalLine + visibleHistogram
            let minValue = allValues.min() ?? 0
            let maxValue = allValues.max() ?? 0

            let yAxisLabels = calculateYAxisLabels(min: minValue, max: maxValue)

            return CalculatedData(
                min: minValue,
                max: maxValue,
                values: (
                    beginIndex: beginIndex,
                    macdLine: macdLine,
                    signalLine: signalLine,
                    histogram: histogram,
                    yAxisLabels: yAxisLabels
                )
            )
        } catch {
            print("Error calculating MACD: \(error)")
            return CalculatedData(min: 0, max: 0, values: (beginIndex: 0, macdLine: [], signalLine: [], histogram: [], yAxisLabels: []))
        }
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let (beginIndex, macdLine, signalLine, histogram, _) = calculatedData.values as? (Int, [Double], [Double], [Double], [Double]),
              !macdLine.isEmpty, !signalLine.isEmpty, !histogram.isEmpty else {
            return []
        }

        let lastVisibleIndex = min(macdLine.count, candlesInfo.endIndex - beginIndex) - 1
        let macdValue = macdLine[lastVisibleIndex]
        let signalValue = signalLine[lastVisibleIndex]
        let histogramValue = histogram[lastVisibleIndex]

        return [
            Text("DIF: \(valueFormatter(macdValue))").font(labelFont).foregroundColor(macdColor),
            Text("DEA: \(valueFormatter(signalValue))").font(labelFont).foregroundColor(signalColor),
            Text("MACD: \(valueFormatter(histogramValue))").font(labelFont).foregroundColor(histogramValue >= 0 ? positiveColor : negativeColor)
        ]
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        guard let (beginIndex, macdLine, signalLine, histogram, yAxisLabels) = calculatedData.values as? (Int, [Double], [Double], [Double], [Double]) else {
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

        // Draw MACD and Signal lines
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: macdLine, color: macdColor)
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: signalLine, color: signalColor)

        // Draw histogram bars
        drawHistogram(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: histogram)
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

    private func drawHistogram(context: GraphicsContext, contextInfo: ContextInfo, beginIndex: Int, values: [Double]) {
        let barWidth = contextInfo.candleWidth

        for (index, value) in values.enumerated() {
            let x = contextInfo.xCoordinate(for: index + beginIndex)
            let y = contextInfo.yCoordinate(for: value)
            let zeroY = contextInfo.yCoordinate(for: 0)

            let barRect = CGRect(
                x: x - barWidth / 2,
                y: min(y, zeroY),
                width: barWidth,
                height: abs(y - zeroY)
            )

            let color = value >= 0 ? positiveColor : negativeColor

            // Determine if the bar should be filled
            let shouldFill: Bool
            if index > 0 {
                let previousValue = values[index - 1]
                if value >= 0 {
                    // For positive values (long position)
                    shouldFill = value < previousValue  // Fill when falling (long fall)
                } else {
                    // For negative values (short position)
                    shouldFill = value < previousValue  // Fill when falling (short fall)
                }
            } else {
                shouldFill = false  // Default for the first bar
            }

            if shouldFill {
                // Fill the bar
                context.fill(Path(barRect), with: .color(color))
            } else {
                // Draw only the outline
                context.stroke(Path(barRect), with: .color(color), lineWidth: lineWidth)
            }
        }
    }

    private func calculateYAxisLabels(min: Double, max: Double) -> [Double] {
        let range = max - min
        if range <= 0.5 {
            // If the range is small, just return one label in the middle
            return [(min + max) / 2].map { $0.rounded(toDecimalPlaces: 2) }
        } else {
            // Otherwise, return two labels
            let lowerLabel = (min + range * 0.25).rounded(toDecimalPlaces: 2)
            let upperLabel = (max - range * 0.25).rounded(toDecimalPlaces: 2)
            return [lowerLabel, upperLabel]
        }
    }
}

extension Double {
    func rounded(toDecimalPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
