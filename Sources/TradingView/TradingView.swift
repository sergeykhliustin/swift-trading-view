import SwiftUI
import SwiftTA

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct TradingView: View {
    let data: [CandleData]
    let primaryContent: [PrimaryContent]
    let candleWidthRange: ClosedRange<CGFloat>
    let candleSpacing: CGFloat
    let scrollTrailingInset: CGFloat

    public init(
        data: [CandleData],
        candleWidth: ClosedRange<CGFloat> = 2...20,
        candleSpacing: CGFloat = 2,
        scrollTrailingInset: CGFloat = 0,
        primaryContent: [PrimaryContent]
    ) {
        self.data = data
        self.primaryContent = primaryContent
        self.candleWidth = (candleWidth.lowerBound + candleWidth.upperBound) / 2
        self.candleWidthRange = candleWidth
        self.candleSpacing = candleSpacing
        self.scrollTrailingInset = scrollTrailingInset
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
                                let yBounds = primaryContent.reduce(
                                    (Double.greatestFiniteMagnitude, Double.zero)
                                ) { result, item in
                                    let bounds = item.calculateYBounds(
                                        candlesInfo: candlesInfo
                                    )
                                    return (min(result.0, bounds.min), max(result.1, bounds.max))
                                }
                                let contextInfo = ContextInfo(
                                    context: context,
                                    contextSize: size,
                                    visibleBounds: CGRect(
                                        origin: CGPoint(x: scrollOffset, y: 0),
                                        size: geometry.size
                                    ),
                                    candleWidth: candleWidth,
                                    candleSpacing: candleSpacing,
                                    verticalPadding: 20,
                                    yBounds: yBounds
                                )
                                primaryContent.forEach {
                                    $0.draw(
                                        contextInfo: contextInfo,
                                        candlesInfo: candlesInfo
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
                    .onChange(of: data.count) { _ in
                        if isScrollAtEnd {
                            scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
                        }
                    }
                    .onChange(of: candleWidth) { _ in
                        scrollViewProxy?.scrollTo("chartEnd", anchor: .trailing)
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
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
struct TradindView_Preview: PreviewProvider {
    static var previews: some View {
        let data = CandleData.generateSampleData(count: 1000)
        return TradingView(
            data: data,
            scrollTrailingInset: 0,
            primaryContent: [
                XAxis(),
                Candles(),
                YAxis(),
                MAIndicator(),
            ]
        )
    }
}
