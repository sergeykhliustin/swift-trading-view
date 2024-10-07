import SwiftUI
import SwiftTA

/// A customizable view for displaying financial trading data with various indicators.
///
/// `TradingView` is a SwiftUI component that renders a scrollable, zoomable chart
/// for displaying candlestick data along with primary and secondary indicators.
/// It supports custom axes, dynamic legends, and interactive gestures for zooming and scrolling.
///
/// # Example Usage:
/// ```swift
/// TradingView(
///     data: data,
///     scrollTrailingInset: 100,
///     primaryContentHeight: 120,
///     primaryContent: [
///         Candles(),
///         MAIndicator(),
///         BBIndicator(),
///     ],
///     secondaryContent: [
///         MACDIndicator()
///     ]
/// )
/// ```
@available(macOS 13.0, iOS 16.0, watchOS 8.0, tvOS 15.0, *)
public struct TradingView: View {
    // MARK: - Properties

    /// The array of candle data to be displayed in the chart.
    public let data: [CandleData]

    /// The y-axis configuration for the chart. If nil, no y-axis will be drawn.
    public let yAxis: Axis?

    /// The x-axis configuration for the chart. If nil, no x-axis will be drawn.
    public let xAxis: Axis?

    /// An array of primary content indicators to be displayed in the main chart area.
    public let primaryContent: [any Content]

    /// An array of secondary content indicators to be displayed below the main chart area.
    public let secondaryContent: [any Content]

    /// The range of possible candle widths for zooming.
    public let candleWidthRange: ClosedRange<CGFloat>

    /// The spacing between individual candles.
    public let candleSpacing: CGFloat

    /// The inset applied to the trailing edge of the scroll view.
    public let scrollTrailingInset: CGFloat

    /// The height of each secondary content indicator.
    public let secondaryContentHeight: CGFloat

    /// The vertical spacing between secondary content indicators.
    public let secondaryContentSpacing: CGFloat

    /// The horizontal spacing between legend items.
    public let legendSpacingX: CGFloat

    /// The vertical spacing between legend items when wrapped to a new line.
    public let legendSpacingY: CGFloat

    /// The leading padding for the legend items.
    public let legendPaddingLeading: CGFloat

    /// The top padding for the content area.
    public let contentPaddingTop: CGFloat

    /// The bottom padding for the content area.
    public let contentPaddingBottom: CGFloat

    /// The height of the primary content area. If nil, it will be calculated automatically.
    public let primaryContentHeight: CGFloat?

    // MARK: - Initializer

    /// Initializes a new instance of `TradingView`.
    ///
    /// - Parameters:
    ///   - data: An array of `CandleData` representing the financial data to be displayed.
    ///   - candleWidth: The range of possible candle widths for zooming.
    ///   - candleSpacing: The spacing between individual candles.
    ///   - scrollTrailingInset: The inset applied to the trailing edge of the scroll view.
    ///   - primaryContentHeight: The height of the primary content area. If nil, it will be calculated automatically.
    ///   - secondaryContentHeight: The height of each secondary content indicator.
    ///   - secondaryContentSpacing: The vertical spacing between secondary content indicators.
    ///   - legendSpacingX: The horizontal spacing between legend items.
    ///   - legendSpacingY: The vertical spacing between legend items when wrapped to a new line.
    ///   - legendPaddingLeading: The leading padding for the legend items.
    ///   - contentPaddingTop: The top padding for the content area.
    ///   - contentPaddingBottom: The bottom padding for the content area.
    ///   - xAxis: The x-axis configuration. If nil, no x-axis will be drawn.
    ///   - yAxis: The y-axis configuration. If nil, no y-axis will be drawn.
    ///   - primaryContent: An array of primary content indicators to be displayed in the main chart area.
    ///   - secondaryContent: An array of secondary content indicators to be displayed below the main chart area.
    public init(
        data: [CandleData],
        candleWidth: ClosedRange<CGFloat> = 2...20,
        candleSpacing: CGFloat = 2,
        scrollTrailingInset: CGFloat = 0,
        primaryContentHeight: CGFloat? = nil,
        secondaryContentHeight: CGFloat = 100,
        secondaryContentSpacing: CGFloat = 5,
        legendSpacingX: CGFloat = 5,
        legendSpacingY: CGFloat = 2,
        legendPaddingLeading: CGFloat = 10,
        contentPaddingTop: CGFloat = 0,
        contentPaddingBottom: CGFloat = 20,
        xAxis: Axis? = XAxis(),
        yAxis: Axis? = YAxis(),
        primaryContent: [any Content],
        secondaryContent: [any Content] = []
    ) {
        self.data = data
        self.xAxis = xAxis
        self.yAxis = yAxis
        self.primaryContent = primaryContent
        self.primaryContentHeight = primaryContentHeight
        self.candleWidth = (candleWidth.lowerBound + candleWidth.upperBound) / 2
        self.candleWidthRange = candleWidth
        self.candleSpacing = candleSpacing
        self.scrollTrailingInset = scrollTrailingInset
        self.secondaryContent = secondaryContent
        self.secondaryContentHeight = secondaryContentHeight
        self.secondaryContentSpacing = secondaryContentSpacing
        self.legendSpacingX = legendSpacingX
        self.legendSpacingY = legendSpacingY
        self.legendPaddingLeading = legendPaddingLeading
        self.contentPaddingTop = contentPaddingTop
        self.contentPaddingBottom = contentPaddingBottom
    }

    @State private var candleWidth: CGFloat
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrollAtEnd = true
    @State private var scrollViewProxy: ScrollViewProxy? {
        didSet {
            scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
        }
    }
    @State private var scrollDisabled = false
    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        Canvas(rendersAsynchronously: false) { context, size in
                            guard let candlesInfo = candlesInfo(for: geometry.size) else {
                                return
                            }
                            let width = min(size.width - scrollOffset, geometry.size.width)
                            let primaryContentBottomOffset =
                                (secondaryContentHeight + secondaryContentSpacing)
                                * CGFloat(secondaryContent.count) + contentPaddingBottom
                            let calculatedData = primaryContent.map({
                                $0.calculate(candlesInfo: candlesInfo)
                            })
                            let yBounds = calculatedData.reduce(
                                (Double.greatestFiniteMagnitude, Double.zero)
                            ) { result, item in
                                (min(result.0, item.min), max(result.1, item.max))
                            }
                            let zipped = zip(primaryContent, calculatedData)
                            let legend = zipped.map({
                                $0.0.legend(candlesInfo: candlesInfo, calculatedData: $0.1)
                            }).flatMap { $0 }
                            let legendSize = legendSize(
                                for: legend,
                                context: context,
                                bounds: CGRect(
                                    origin: CGPoint(x: scrollOffset + legendPaddingLeading, y: contentPaddingTop),
                                    size: CGSize(width: width, height: geometry.size.height - primaryContentBottomOffset)
                                ),
                                spacingX: legendSpacingX,
                                spacingY: legendSpacingY
                            )
                            let contextInfo = ContextInfo(
                                context: context,
                                contextSize: size,
                                visibleBounds: CGRect(
                                    origin: CGPoint(x: scrollOffset, y: contentPaddingTop + legendSize.height),
                                    size: CGSize(
                                        width: width,
                                        height: size.height
                                            - primaryContentBottomOffset - contentPaddingTop - legendSize.height
                                    )
                                ),
                                candleWidth: candleWidth,
                                candleSpacing: candleSpacing,
                                yBounds: yBounds
                            )
                            yAxis?
                                .draw(
                                    contextInfo: contextInfo,
                                    candlesInfo: candlesInfo
                                )
                            xAxis?
                                .draw(
                                    contextInfo: contextInfo,
                                    candlesInfo: candlesInfo
                                )
                            zipped
                                .forEach {
                                    $0.0.draw(
                                        contextInfo: contextInfo,
                                        candlesInfo: candlesInfo,
                                        calculatedData: $0.1
                                    )
                                }

                            drawLegend(
                                context: context,
                                bounds: CGRect(
                                    origin: CGPoint(
                                        x: scrollOffset + legendPaddingLeading,
                                        y: contentPaddingTop
                                    ),
                                    size: CGSize(
                                        width: width,
                                        height: geometry.size.height - primaryContentBottomOffset
                                    )
                                ),
                                text: legend,
                                spacingX: legendSpacingX,
                                spacingY: legendSpacingY
                            )
                            for (index, content) in secondaryContent.reversed().enumerated() {
                                let calculatedData = content.calculate(candlesInfo: candlesInfo)
                                let y =
                                    size.height - secondaryContentHeight
                                    * CGFloat(index + 1) - secondaryContentSpacing * CGFloat(index)
                                    - contentPaddingBottom
                                let legend = content.legend(
                                    candlesInfo: candlesInfo,
                                    calculatedData: calculatedData
                                )
                                let legendSize = self.legendSize(
                                    for: legend,
                                    context: context,
                                    bounds: CGRect(
                                        origin: CGPoint(x: scrollOffset + legendPaddingLeading, y: y),
                                        size: CGSize(width: width, height: secondaryContentHeight)
                                    ),
                                    spacingX: legendSpacingX,
                                    spacingY: legendSpacingY
                                )
                                let contextInfo = ContextInfo(
                                    context: context,
                                    contextSize: size,
                                    visibleBounds: CGRect(
                                        origin: CGPoint(
                                            x: scrollOffset,
                                            y: y + legendSize.height
                                        ),
                                        size: CGSize(
                                            width: width,
                                            height: secondaryContentHeight - legendSize.height
                                        )
                                    ),
                                    candleWidth: candleWidth,
                                    candleSpacing: candleSpacing,
                                    yBounds: (min: calculatedData.min, max: calculatedData.max)
                                )
                                content.draw(
                                    contextInfo: contextInfo,
                                    candlesInfo: candlesInfo,
                                    calculatedData: calculatedData
                                )
                                drawLegend(
                                    context: context,
                                    bounds: CGRect(
                                        origin: CGPoint(
                                            x: scrollOffset + legendPaddingLeading,
                                            y: y
                                        ),
                                        size: CGSize(
                                            width: width,
                                            height: secondaryContentHeight
                                        )
                                    ),
                                    text: content.legend(
                                        candlesInfo: candlesInfo,
                                        calculatedData: calculatedData
                                    ),
                                    spacingX: legendSpacingX,
                                    spacingY: legendSpacingY
                                )
                            }
                        }
                        .frame(
                            width: CGFloat(data.count)
                                * (candleWidth + candleSpacing)
                                + scrollTrailingInset,
                            height: primaryContentHeight != nil
                                ? primaryContentHeight! + contentPaddingTop + contentPaddingBottom
                                    + (secondaryContentHeight + secondaryContentSpacing)
                                    * CGFloat(secondaryContent.count) : nil
                        )

                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("scroll")).minX
                            )
                        }
                    }
                    .id("chartEnd")
                }
                .coordinateSpace(name: "scroll")
                .scrollDisabled(scrollDisabled)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = -value

                    // Calculate if we're at the end
                    let contentWidth =
                        CGFloat(data.count) * (candleWidth + candleSpacing)
                        + scrollTrailingInset
                    let viewportWidth = geometry.size.width
                    isScrollAtEnd = abs(value) >= contentWidth - viewportWidth - 1  // 1 point tolerance
                }
                .onAppear {
                    scrollViewProxy = proxy
                }
                #if !os(watchOS) && !os(tvOS)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { val in
                                self.scrollDisabled = true
                                let delta = val / self.lastScaleValue
                                self.lastScaleValue = val
                                let newScale = self.candleWidth * delta

                                if candleWidthRange.contains(newScale) {
                                    let oldContentWidth =
                                    CGFloat(data.count) * (candleWidth + candleSpacing)
                                    + scrollTrailingInset
                                    let newContentWidth =
                                    CGFloat(data.count) * (newScale + candleSpacing)
                                    + scrollTrailingInset
                                    let viewportWidth = geometry.size.width

                                    // Calculate the center point of the visible content
                                    let visibleCenter = scrollOffset + viewportWidth / 2

                                    // Calculate the proportion of the content that is to the left of the center
                                    let proportion = visibleCenter / oldContentWidth

                                    // Calculate the new scroll offset to maintain the same center
                                    let newScrollOffset = (newContentWidth * proportion) - (viewportWidth / 2)

                                    // Update the candleWidth
                                    self.candleWidth = newScale

                                    // Apply the new scroll offset
                                    scrollViewProxy?.scrollTo(
                                        "chartEnd",
                                        anchor: UnitPoint(
                                            x: newScrollOffset / (newContentWidth - viewportWidth),
                                            y: 0
                                        )
                                    )
                                }
                            }
                            .onEnded { _ in
                                // without this the next gesture will be broken
                                self.lastScaleValue = 1.0
                                withAnimation(.default.delay(0.5)) {
                                    self.scrollDisabled = false
                                }
                            }
                    )
                #elseif os(watchOS)
                    .focusable()
                    .digitalCrownRotation(
                        $candleWidth,
                        from: candleWidthRange.lowerBound,
                        through: candleWidthRange.upperBound,
                        by: (candleWidthRange.upperBound - candleWidthRange.lowerBound) / 20,
                        sensitivity: .low
                    )
                #endif
                #if os(visionOS)
                    .onChange(of: data.count) { _, _ in
                        if isScrollAtEnd {
                            scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
                        }
                    }
                #else
                    .onChange(of: data.count) { _ in
                        if isScrollAtEnd {
                            scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
                        }
                    }
                #endif
            }
        }
        .frame(
            height: primaryContentHeight != nil
                ? primaryContentHeight! + contentPaddingTop + contentPaddingBottom
                    + (secondaryContentHeight + secondaryContentSpacing)
                    * CGFloat(secondaryContent.count) : nil
        )
    }

    private func candlesInfo(for visibleSize: CGSize) -> CandlesInfo? {
        let visibleItemCount =
            Int(visibleSize.width / (candleWidth + candleSpacing)) + 1
        let startIndex = max(0, Int(scrollOffset / (candleWidth + candleSpacing)))
        let endIndex = min(data.count, startIndex + visibleItemCount)
        return CandlesInfo(
            data: data,
            startIndex: startIndex,
            endIndex: endIndex
        )
    }

    private func legendSize(
        for text: [Text],
        context: GraphicsContext,
        bounds: CGRect,
        spacingX: CGFloat,
        spacingY: CGFloat
    ) -> CGSize {
        let textSizes = text.map { context.resolve($0) }.map { $0.measure(in: bounds.size) }
        let width = textSizes.reduce(0) { $0 + $1.width + spacingX }
        let height = textSizes.reduce(0) { max($0, $1.height) } * ceil(width / bounds.width)
        return CGSize(width: min(width, bounds.width), height: height)
    }

    private func drawLegend(
        context: GraphicsContext,
        bounds: CGRect,
        text: [Text],
        spacingX: CGFloat,
        spacingY: CGFloat
    ) {
        let resolvedTexts = text.map { context.resolve($0) }
        var x: CGFloat = max(bounds.minX, 0)
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

@available(macOS 13.0, iOS 16.0, watchOS 8.0, tvOS 15.0, *)
struct TradingView_Preview: PreviewProvider {
    @ViewBuilder
    static var previews: some View {
        let data = CandleData.generateSampleData(count: 1000)
        TradingView(
            data: data,
            scrollTrailingInset: 100,
            primaryContentHeight: 120,
            primaryContent: [
                Candles(),
                MAIndicator(),
                BBIndicator(),
            ],
            secondaryContent: [
                MACDIndicator(),
                VolumeIndicator()
            ]
        )
    }
}
