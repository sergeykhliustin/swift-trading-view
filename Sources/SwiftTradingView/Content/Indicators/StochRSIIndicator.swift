import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct StochRSIIndicator: Content {
    public var timePeriod: Int
    public var fastKPeriod: Int
    public var fastDPeriod: Int
    public var fastDMAType: MAType
    public var kColor: Color
    public var dColor: Color
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var valueFormatter: (Double) -> String
    public var yAxisLabelColor: Color

    public init(
        timePeriod: Int = 14,
        fastKPeriod: Int = 3,
        fastDPeriod: Int = 3,
        fastDMAType: MAType = .sma,
        kColor: Color = .blue,
        dColor: Color = .red,
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        yAxisLabelColor: Color = .black
    ) {
        self.timePeriod = timePeriod
        self.fastKPeriod = fastKPeriod
        self.fastDPeriod = fastDPeriod
        self.fastDMAType = fastDMAType
        self.kColor = kColor
        self.dColor = dColor
        self.labelFont = labelFont
        self.lineWidth = lineWidth
        self.valueFormatter = valueFormatter
        self.yAxisLabelColor = yAxisLabelColor
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let closes = candlesInfo.data.map { $0.close }
        do {
            let (beginIndex, fastK, fastD) = try TALib.StochRSI(
                inReal: closes,
                timePeriod: timePeriod,
                fastKPeriod: fastKPeriod,
                fastDPeriod: fastDPeriod,
                fastDMAType: fastDMAType
            )

            let visibleStartIndex = max(candlesInfo.startIndex - beginIndex, 0)
            let visibleEndIndex = min(candlesInfo.endIndex - beginIndex, fastK.count)

            guard visibleStartIndex < visibleEndIndex else {
                return CalculatedData(min: 0, max: 100, values: (beginIndex: 0, fastK: [], fastD: [], yAxisLabels: []))
            }

            let visibleFastK = Array(fastK[visibleStartIndex..<visibleEndIndex])
            let visibleFastD = Array(fastD[visibleStartIndex..<visibleEndIndex])

            let allValues = visibleFastK + visibleFastD
            let minValue = max(allValues.min() ?? 0, 0)  // Ensure minimum is not less than 0
            let maxValue = min(allValues.max() ?? 100, 100)  // Ensure maximum is not more than 100

            let yAxisLabels = calculateYAxisLabels(min: minValue, max: maxValue)

            return CalculatedData(
                min: minValue,
                max: maxValue,
                values: (
                    beginIndex: beginIndex,
                    fastK: fastK,
                    fastD: fastD,
                    yAxisLabels: yAxisLabels
                )
            )
        } catch {
            print("Error calculating StochRSI: \(error)")
            return CalculatedData(min: 0, max: 100, values: (beginIndex: 0, fastK: [], fastD: [], yAxisLabels: []))
        }
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let (beginIndex, fastK, fastD, _) = calculatedData.values as? (Int, [Double], [Double], [Double]),
              !fastK.isEmpty, !fastD.isEmpty else {
            return []
        }

        let lastVisibleIndex = min(fastK.count, candlesInfo.endIndex - beginIndex) - 1
        let kValue = fastK[lastVisibleIndex]
        let dValue = fastD[lastVisibleIndex]

        return [
            Text("K: \(valueFormatter(kValue))").font(labelFont).foregroundColor(kColor),
            Text("D: \(valueFormatter(dValue))").font(labelFont).foregroundColor(dColor)
        ]
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        guard let (beginIndex, fastK, fastD, yAxisLabels) = calculatedData.values as? (Int, [Double], [Double], [Double]) else {
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

        // Draw K and D lines
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: fastK, color: kColor)
        drawLine(context: context, contextInfo: contextInfo, beginIndex: beginIndex, values: fastD, color: dColor)
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
        return [20, 50, 80].filter { $0 > min && $0 < max }
    }
}
