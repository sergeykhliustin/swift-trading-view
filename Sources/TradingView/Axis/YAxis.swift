import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct YAxis: Axis {
    public var labelFont: Font
    public var labelColor: Color
    public var labelFormatter: (Double) -> String
    public var negativeCandleColor: Color
    public var positiveCandleColor: Color
    public var lineColor: Color
    public var labelsCount: Int

    /// Initializes a new instance of `YAxis` with customizable appearance and behavior.
    ///
    /// - Parameters:
    ///   - negativeCandleColor: The color used for negative (bearish) candles. Default is red.
    ///   - positiveCandleColor: The color used for positive (bullish) candles. Default is green.
    ///   - lineColor: The color of the horizontal grid lines. Default is gray.
    ///   - labelFont: The font used for y-axis labels. Default is system font with size 10.
    ///   - labelColor: The color of the y-axis label text. Default is black.
    ///   - labelsCount: The number of labels (and grid lines) to display on the y-axis. Default is 4.
    ///   - labelFormatter: A closure that formats the y-axis label values. Default formats to two decimal places.
    public init(
        negativeCandleColor: Color = Color.red,
        positiveCandleColor: Color = Color.green,
        lineColor: Color = Color.gray,
        labelFont: Font = Font.system(size: 10),
        labelColor: Color = Color.black,
        labelsCount: Int = 4,
        labelFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) }
    ) {
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.negativeCandleColor = negativeCandleColor
        self.positiveCandleColor = positiveCandleColor
        self.lineColor = lineColor
        self.labelsCount = labelsCount
        self.labelFormatter = labelFormatter
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    ) {
        guard labelsCount > 2 else {
            return
        }
        let context = contextInfo.context
        let contextSize = contextInfo.contextSize
        let yBounds = contextInfo.yBounds

        let yAxisLabels = stride(from: yBounds.min, through: yBounds.max, by: (yBounds.max - yBounds.min) / Double(labelsCount - 1))

        let labelX = contextInfo.visibleBounds.maxX

        // Draw y-axis labels and lines
        for value in yAxisLabels {
            let y = contextInfo.yCoordinate(for: value)

            // Draw horizontal line
            let linePath = Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: contextSize.width, y: y))
            }
            context.stroke(linePath, with: .color(lineColor), lineWidth: 1)
            drawText(
                context: context,
                contextSize: contextSize,
                text: labelFormatter(value),
                at: CGPoint(x: labelX, y: y)
            )
        }

        // Draw last price line
        if let last = candlesInfo.data.last {
            let color = last.open > last.close ? negativeCandleColor : positiveCandleColor
            let value = last.close
            let y = contextInfo.yCoordinate(for: value)

            if contextInfo.visibleBounds.contains(CGPoint(x: contextInfo.visibleBounds.midX, y: y)) {

                let linePath = Path { path in
                    path.move(to: CGPoint(x: contextInfo.visibleBounds.minX, y: y))
                    path.addLine(to: CGPoint(x: contextInfo.visibleBounds.maxX, y: y))
                }
                context.stroke(
                    linePath,
                    with: .color(color),
                    style: .init(lineWidth: 1, dash: [2, 2])
                )
                drawText(
                    context: context,
                    contextSize: contextSize,
                    text: labelFormatter(value),
                    at: CGPoint(x: labelX, y: y),
                    color: color
                )

            }
        }
    }

    private func drawText(
        context: GraphicsContext,
        contextSize: CGSize,
        text: String,
        at point: CGPoint,
        color: Color? = nil
    ) {
        let text = Text(text)
            .font(labelFont)
            .foregroundColor(color ?? labelColor)
        let resolvedText = context.resolve(text)
        let textSize = resolvedText.measure(in: contextSize)
        // Draw text
        context.draw(
            text,
            at: CGPoint(x: point.x - textSize.width, y: point.y - textSize.height),
            anchor: .topLeading
        )
    }
}
