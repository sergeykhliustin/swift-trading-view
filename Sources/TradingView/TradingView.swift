import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct TradingView: View {
    let data: [CandleData]
    let yAxis: Axis?
    let xAxis: Axis?
    let primaryContent: [any Content]
    let secondaryContent: [any Content]
    let candleWidthRange: ClosedRange<CGFloat>
    let candleSpacing: CGFloat
    let scrollTrailingInset: CGFloat
    let secondaryContentHeight: CGFloat
    let secondaryContentSpacing: CGFloat
    let legendSpacingX: CGFloat
    let legendSpacingY: CGFloat
    let legendPaddingLeading: CGFloat
    let contentPaddingTop: CGFloat
    let contentPaddingBottom: CGFloat

    public init(
        data: [CandleData],
        candleWidth: ClosedRange<CGFloat> = 2...20,
        candleSpacing: CGFloat = 2,
        scrollTrailingInset: CGFloat = 0,
        secondaryContentHeight: CGFloat = 100,
        secondaryContentSpacing: CGFloat = 5,
        legendSpacingX: CGFloat = 5,
        legendSpacingY: CGFloat = 2,
        legendPaddingLeading: CGFloat = 10,
        contentPaddingTop: CGFloat = 15,
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
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            Canvas(rendersAsynchronously: true) { context, size in
                                guard let candlesInfo = candlesInfo(for: geometry.size) else {
                                    return
                                }
                                let primaryContentBottomOffset =
                                    (secondaryContentHeight + secondaryContentSpacing) * CGFloat(secondaryContent.count) + contentPaddingBottom
                                let calculatedData = primaryContent.map({
                                    $0.calculate(candlesInfo: candlesInfo)
                                })
                                let yBounds = calculatedData.reduce(
                                    (Double.greatestFiniteMagnitude, Double.zero)
                                ) { result, item in
                                    (min(result.0, item.min), max(result.1, item.max))
                                }
                                let width = min(size.width - scrollOffset, geometry.size.width)
                                let contextInfo = ContextInfo(
                                    context: context,
                                    contextSize: size,
                                    visibleBounds: CGRect(
                                        origin: CGPoint(x: scrollOffset, y: contentPaddingTop),
                                        size: CGSize(
                                            width: width,
                                            height: geometry.size.height
                                                - primaryContentBottomOffset - contentPaddingTop
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
                                let zipped = zip(primaryContent, calculatedData)
                                zipped
                                    .forEach {
                                        $0.0.draw(
                                            contextInfo: contextInfo,
                                            candlesInfo: candlesInfo,
                                            calculatedData: $0.1
                                        )
                                    }
                                let legend = zipped.map({
                                    $0.0.legend(candlesInfo: candlesInfo, calculatedData: $0.1)
                                })
                                flowLayout(
                                    context: context,
                                    bounds: CGRect(
                                        origin: CGPoint(
                                            x: scrollOffset + legendPaddingLeading,
                                            y: 0
                                        ),
                                        size: CGSize(
                                            width: width,
                                            height: geometry.size.height - primaryContentBottomOffset
                                        )
                                    ),
                                    text: legend.flatMap { $0 },
                                    spacingX: legendSpacingX,
                                    spacingY: legendSpacingY
                                )
                                for (index, content) in secondaryContent.enumerated() {
                                    let calculatedData = content.calculate(candlesInfo: candlesInfo)
                                    let contextInfo = ContextInfo(
                                        context: context,
                                        contextSize: size,
                                        visibleBounds: CGRect(
                                            origin: CGPoint(
                                                x: scrollOffset,
                                                y: size.height - secondaryContentHeight
                                                    * CGFloat(index + 1) - secondaryContentSpacing * CGFloat(index) - contentPaddingBottom
                                            ),
                                            size: CGSize(
                                                width: width,
                                                height: secondaryContentHeight
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
                                    flowLayout(
                                        context: context,
                                        bounds: CGRect(
                                            origin: CGPoint(
                                                x: scrollOffset + legendPaddingLeading,
                                                y: size.height - secondaryContentHeight
                                                    * CGFloat(index + 1) - secondaryContentSpacing * CGFloat(index) - contentPaddingBottom
                                            ),
                                            size: CGSize(
                                                width: width,
                                                height: secondaryContentHeight
                                            )
                                        ),
                                        text: content.legend(candlesInfo: candlesInfo, calculatedData: calculatedData),
                                        spacingX: legendSpacingX,
                                        spacingY: legendSpacingY
                                    )
                                }
                            }
                            .frame(
                                width: CGFloat(data.count)
                                    * (candleWidth + candleSpacing)
                                    + scrollTrailingInset
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
                                    let delta = val / self.lastScaleValue
                                    self.lastScaleValue = val
                                    let newScale = self.candleWidth * delta

                                    if candleWidthRange.contains(newScale) {
                                        self.candleWidth = newScale
                                    }
                                }
                                .onEnded { _ in
                                    // without this the next gesture will be broken
                                    self.lastScaleValue = 1.0
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
                        .onChange(of: candleWidth) { _, _ in
                            scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
                        }
                    #else
                        .onChange(of: data.count) { _ in
                            if isScrollAtEnd {
                                scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
                            }
                        }
                        .onChange(of: candleWidth) { _ in
                            scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
                        }
                    #endif
                }
            }
        }
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

    private func flowLayout(
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

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
struct TradingView_Preview: PreviewProvider {
    @ViewBuilder
    static var previews: some View {
        let data = CandleData.generateSampleData(count: 1000)
        TradingView(
            data: data,
            scrollTrailingInset: 100,
            primaryContent: [
                Candles(),
                MAIndicator(),
                BBIndicator(),
            ],
            secondaryContent: [
                RSIIndicator(),
                RSIIndicator()
            ]
        )
    }
}
