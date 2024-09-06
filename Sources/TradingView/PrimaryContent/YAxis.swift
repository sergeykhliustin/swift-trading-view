import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
public struct YAxis: PrimaryContent {
    public var labelFont: Font
    public var labelColor: Color
    public var labelBackgroundColor: Color
    public var labelFormatter: (Double) -> String
    public var negativeCandleColor: Color
    public var positiveCandleColor: Color
    public var lineColor: Color

    public init(
        negativeCandleColor: Color = Color.red,
        positiveCandleColor: Color = Color.green,
        lineColor: Color = Color.gray,
        labelFont: Font = Font.system(size: 10),
        labelColor: Color = Color.black,
        labelBackgroundColor: Color = Color.white,
        labelFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) }
    ) {
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.negativeCandleColor = negativeCandleColor
        self.positiveCandleColor = positiveCandleColor
        self.lineColor = lineColor
        self.labelBackgroundColor = labelBackgroundColor
        self.labelFormatter = labelFormatter
    }

    public func calculateYBounds(candlesInfo: CandlesInfo) -> (min: Double, max: Double) {
        let (minLow, maxHigh) = candlesInfo.visibleData.reduce((Double.greatestFiniteMagnitude, Double.zero)) { result, item in
            (min(result.0, item.low), max(result.1, item.high))
        }
        return (min: minLow, max: maxHigh)
    }

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    ) {
        let context = contextInfo.context
        let contextSize = contextInfo.contextSize
        let yBounds = contextInfo.yBounds
        let verticalPadding = contextInfo.verticalPadding
        let yScale = contextInfo.yScale

        let yAxisLabels = stride(from: yBounds.min, through: yBounds.max, by: (yBounds.max - yBounds.min) / 3)

        var labelX = contextInfo.visibleBounds.maxX

        if labelX > contextSize.width {
            labelX = contextSize.width
        }

        // Draw y-axis labels and lines
        for value in yAxisLabels {
            let y = verticalPadding + CGFloat(yBounds.max - value) * yScale

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
                at: CGPoint(x: labelX, y: y),
                backgroundColor: labelBackgroundColor
            )
        }

        // Draw last price line
        if let last = candlesInfo.data.last {
            let color = last.open > last.close ? negativeCandleColor : positiveCandleColor
            let value = last.close
            let y = verticalPadding + CGFloat(yBounds.max - value) * yScale

            let linePath = Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: contextSize.width, y: y))
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
                backgroundColor: color
            )
        }
    }

    private func drawText(
        context: GraphicsContext,
        contextSize: CGSize,
        text: String,
        at point: CGPoint,
        backgroundColor: Color
    ) {
        let text = Text(text)
            .font(labelFont)
            .foregroundColor(labelColor)
        let resolvedText = context.resolve(text)
        let textSize = resolvedText.measure(in: contextSize)
        // Calculate background rect with padding
        let padding: CGFloat = 2
        let backgroundRect = CGRect(
            x: point.x - textSize.width - padding * 2,
            y: point.y - textSize.height / 2 - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        // Draw background
        let backgroundPath = Path(roundedRect: backgroundRect, cornerRadius: 2)
        context.fill(backgroundPath, with: .color(backgroundColor))
        // Draw text
        context.draw(
            text,
            at: CGPoint(x: point.x - textSize.width - padding, y: point.y - textSize.height / 2),
            anchor: .topLeading
        )
    }
}
