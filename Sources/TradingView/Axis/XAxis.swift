import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct XAxis: Axis {
    public var lineColor: Color
    public var labelFont: Font
    public var labelColor: Color
    public var labelBackgroundColor: Color
    public var labelBackgroundPadding: CGFloat
    public var labelBackgroundCornerRadius: CGFloat
    public var labelInterval: Int
    public var labelFormatter: (Double) -> String

    /// Initializes a new instance of `XAxis` with customizable appearance and behavior.
    ///
    /// - Parameters:
    ///   - lineColor: The color of the vertical grid lines. Default is gray.
    ///   - labelFont: The font used for x-axis labels. Default is system font with size 10.
    ///   - labelColor: The color of the x-axis label text. Default is black.
    ///   - labelBackgroundColor: The background color of the x-axis labels. Default is white.
    ///   - labelBackgroundPadding: The padding around the label text within its background. Default is 2 points.
    ///   - labelBackgroundCornerRadius: The corner radius of the label background. Default is 2 points.
    ///   - labelInterval: The interval at which to display labels on the x-axis. Default is every 10 candles.
    ///   - labelFormatter: A closure that formats the x-axis label values. Default formats timestamps to "HH:mm" format.
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

    public func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    ) {

        let context = contextInfo.context
        let contextSize = contextInfo.contextSize

        for (index, item) in candlesInfo.visibleData.enumerated() {
            if (index + candlesInfo.startIndex).isMultiple(of: labelInterval) {
                let x = contextInfo.xCoordinate(for: index + candlesInfo.startIndex)

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
