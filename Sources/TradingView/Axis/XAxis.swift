import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct XAxis: Axis {
    public var lineColor: Color
    public var labelFont: Font
    public var labelColor: Color
    public var labelInterval: Int
    public var labelFormatter: (Double) -> String

    /// Initializes a new instance of `XAxis` with customizable appearance and behavior.
    ///
    /// - Parameters:
    ///   - lineColor: The color of the vertical grid lines. Default is gray.
    ///   - labelFont: The font used for x-axis labels. Default is system font with size 10.
    ///   - labelColor: The color of the x-axis label text. Default is black.
    ///   - labelInterval: The interval at which to display labels on the x-axis. Default is every 10 candles.
    ///   - labelFormatter: A closure that formats the x-axis label values. Default formats timestamps to "HH:mm" format.
    public init(
        lineColor: Color = Color.gray,
        labelFont: Font = Font.system(size: 10),
        labelColor: Color = Color.black,
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

                let text = Text(labelFormatter(item.time))
                    .font(labelFont)
                    .foregroundColor(labelColor)
                let resolvedText = context.resolve(text)
                let textSize = resolvedText.measure(in: contextSize)

                let y = contextSize.height - textSize.height / 2

                context.draw(
                    text,
                    at: CGPoint(
                        x: x,
                        y: y
                    ),
                    anchor: .center
                )

                let linePath = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: contextSize.height - textSize.height))
                }
                context.stroke(linePath, with: .color(lineColor), lineWidth: 1)
            }
        }
    }
}
