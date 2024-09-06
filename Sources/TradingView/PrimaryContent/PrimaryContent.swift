import Foundation
import SwiftUI

public protocol PrimaryContent {
    func calculateYBounds(
        candlesInfo: CandlesInfo
    ) -> (min: Double, max: Double)

    func draw(
        contextInfo: ContextInfo,
        candlesInfo: CandlesInfo
    )
}

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
