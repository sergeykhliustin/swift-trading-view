import Foundation
import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct BBIndicator: PrimaryContent {
    public var calculatingPeriod: Int
    public var bandwidth: Double
    public var maType: MAType
    public var upColor: Color
    public var mbColor: Color
    public var dnColor: Color
    public var labelFont: Font
    public var lineWidth: CGFloat
    public var valueFormatter: (Double) -> String

    public init(
        calculatingPeriod: Int = 20,
        bandwidth: Double = 2.0,
        maType: MAType = .sma,
        upColor: Color = .red,
        mbColor: Color = .yellow,
        dnColor: Color = .green,
        labelFont: Font = Font.system(size: 10),
        lineWidth: CGFloat = 1.0,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) }
    ) {
        self.calculatingPeriod = calculatingPeriod
        self.bandwidth = bandwidth
        self.maType = maType
        self.upColor = upColor
        self.mbColor = mbColor
        self.dnColor = dnColor
        self.labelFont = labelFont
        self.lineWidth = lineWidth
        self.valueFormatter = valueFormatter
    }

    public func calculate(candlesInfo: CandlesInfo) -> CalculatedData {
        let closes = candlesInfo.data.map { $0.close }
        do {
            let (upperBand, middleBand, lowerBand) = try TALib.BBANDS(
                inReal: closes,
                timePeriod: calculatingPeriod,
                nbDevUp: bandwidth,
                nbDevDn: bandwidth,
                maType: maType
            )

            let beginIndex = candlesInfo.data.count - upperBand.count
            let visibleUpperBand = Array(
                upperBand[
                    max(
                        candlesInfo.startIndex - beginIndex,
                        0
                    )..<min(candlesInfo.endIndex - beginIndex, upperBand.count)
                ]
            )
            let visibleMiddleBand = Array(
                middleBand[
                    max(
                        candlesInfo.startIndex - beginIndex,
                        0
                    )..<min(candlesInfo.endIndex - beginIndex, middleBand.count)
                ]
            )
            let visibleLowerBand = Array(
                lowerBand[
                    max(
                        candlesInfo.startIndex - beginIndex,
                        0
                    )..<min(candlesInfo.endIndex - beginIndex, lowerBand.count)
                ]
            )

            let allVisibleValues =
                visibleUpperBand + visibleMiddleBand + visibleLowerBand
                + candlesInfo.visibleData.map { $0.close }

            // Calculate bandwidths
            let bandwidths = zip(zip(upperBand, middleBand), lowerBand)
                .map {
                    calculateBandwidth(upper: $0.0, middle: $0.1, lower: $1)
                }

            return CalculatedData(
                min: allVisibleValues.min() ?? 0,
                max: allVisibleValues.max() ?? 0,
                values: [
                    "upper": upperBand,
                    "middle": middleBand,
                    "lower": lowerBand,
                    "bandwidths": bandwidths,
                ]
            )
        } catch {
            print("Error calculating Bollinger Bands: \(error)")
            return CalculatedData(min: 0, max: 0, values: [:])
        }
    }

    private func calculateBandwidth(upper: Double, middle: Double, lower: Double) -> Double {
        return (upper - lower) / middle
    }

    public func legend(candlesInfo: CandlesInfo, calculatedData: CalculatedData) -> [Text] {
        guard let values = calculatedData.values as? [String: [Double]],
            let upperBand = values["upper"],
            let middleBand = values["middle"],
            let lowerBand = values["lower"]
        else {
            return []
        }

        let beginIndex = candlesInfo.data.count - upperBand.count
        let lastVisibleIndex = min(upperBand.count, candlesInfo.endIndex - beginIndex) - 1

        return [
            Text("BOLL:(\(calculatingPeriod), \(String(format: "%.2f", bandwidth)))")
                .font(labelFont).foregroundColor(upColor),
            Text("UP: \(valueFormatter(upperBand[lastVisibleIndex]))").font(labelFont)
                .foregroundColor(upColor),
            Text("MB: \(valueFormatter(middleBand[lastVisibleIndex]))").font(labelFont)
                .foregroundColor(mbColor),
            Text("DN: \(valueFormatter(lowerBand[lastVisibleIndex]))").font(labelFont)
                .foregroundColor(dnColor),
        ]
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo,
        calculatedData: CalculatedData
    ) {
        let context = contextInfo.context

        guard let values = calculatedData.values as? [String: [Double]],
            let upperBand = values["upper"],
            let middleBand = values["middle"],
            let lowerBand = values["lower"]
        else {
            return
        }

        let beginIndex = candlesInfo.data.count - upperBand.count

        let drawBand = { (band: [Double], color: Color) in
            let path = Path { path in
                for (index, value) in band.enumerated() {
                    let x = contextInfo.xCoordinate(for: index + beginIndex)
                    let y = contextInfo.yCoordinate(for: value)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }

        drawBand(upperBand, upColor)
        drawBand(middleBand, mbColor)
        drawBand(lowerBand, dnColor)
    }
}
