import Foundation
import SwiftUI

@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
public protocol PrimaryContent {
    func calculateYBounds(
        candlesInfo: CandlesInfo
    ) -> (min: Double, max: Double)

    func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    )
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
extension PrimaryContent {
    func flowLayout(
        context: GraphicsContext,
        bounds: CGRect,
        text: [Text],
        spacingX: CGFloat,
        spacingY: CGFloat
    ) {
        let resolvedTexts = text.map { context.resolve($0) }
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        for (_, resolvedText) in resolvedTexts.enumerated() {
            let textSize = resolvedText.measure(in: bounds.size)
            if x + textSize.width > bounds.maxX {
                x = bounds.minX
                y += textSize.height + spacingY
            }
            context.draw(
                resolvedText,
                at: CGPoint(x: x, y: y),
                anchor: .topLeading
            )
            x += textSize.width + spacingX
        }
    }
}
