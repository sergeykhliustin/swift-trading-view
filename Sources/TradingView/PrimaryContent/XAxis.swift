import Foundation
import SwiftUI

public struct XAxis: PrimaryContent {
    public var lineColor: Color
    public var labelFont: Font
    public var labelColor: Color
    public var labelBackgroundColor: Color
    public var labelBackgroundPadding: CGFloat
    public var labelBackgroundCornerRadius: CGFloat
    public var labelInterval: Int
    public var labelFormatter: (Double) -> String

    public init(
        lineColor: Color = Color.gray,
        labelFont: Font = Font.system(size: 10),
        labelColor: Color = Color.black,
        labelBackgroundColor: Color = Color.white,
        labelBackgroundPadding: CGFloat = 2,
        labelBackgroundCornerRadius: CGFloat = 2,
        labelInterval: Int = 10,
        labelFormatter: @escaping (Double) -> String = {
            let date = Date(timeIntervalSince1970: $0)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        }
    ) {
        self.lineColor = lineColor
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.labelBackgroundColor = labelBackgroundColor
        self.labelBackgroundPadding = labelBackgroundPadding
        self.labelBackgroundCornerRadius = labelBackgroundCornerRadius
        self.labelInterval = labelInterval
        self.labelFormatter = labelFormatter
    }

    public func calculateYBounds(candlesInfo: CandlesInfo) -> (min: Double, max: Double) {
        let (minLow, maxHigh) = candlesInfo.visibleData.reduce(
            (Double.greatestFiniteMagnitude, Double.zero)
        ) { result, item in
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
        let candleWidth = contextInfo.candleWidth
        let candleSpacing = contextInfo.candleSpacing

        for (index, item) in candlesInfo.visibleData.enumerated() {
            if (index + candlesInfo.startIndex).isMultiple(of: labelInterval) {
                let x =
                    CGFloat(index + candlesInfo.startIndex) * (candleWidth + candleSpacing)
                    + candleWidth / 2
                let linePath = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: contextSize.height))
                }
                context.stroke(linePath, with: .color(lineColor), lineWidth: 1)

                let text = Text(labelFormatter(item.time))
                    .font(labelFont)
                    .foregroundColor(labelColor)
                let resolvedText = context.resolve(text)
                let textSize = resolvedText.measure(in: contextSize)

                let bgPadding = labelBackgroundPadding
                let y = contextSize.height - textSize.height / 2 - bgPadding

                let backgroundRect = CGRect(
                    x: x - textSize.width / 2 - bgPadding,
                    y: y - textSize.height / 2 - bgPadding,
                    width: textSize.width + bgPadding * 2,
                    height: textSize.height + bgPadding * 2
                )

                let backgroundPath = Path(roundedRect: backgroundRect, cornerRadius: labelBackgroundCornerRadius)
                context.fill(backgroundPath, with: .color(labelBackgroundColor))

                context.draw(
                    text,
                    at: CGPoint(
                        x: x,
                        y: y
                    ),
                    anchor: .center
                )
            }
        }
    }
}
