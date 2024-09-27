# Swift Trading View

Swift Trading View is a powerful, highly optimized, customizable financial charting library for iOS, macOS, watchOS, tvOS, and visionOS applications. It provides a Binance-like trading view interface, allowing developers to integrate professional-grade financial charts into their Swift applications easily.

<img width="603" alt="image" src="https://github.com/user-attachments/assets/06eae894-0407-4d95-8ee8-ed8aa6c8a537">

<details>
<summary>iOS</summary>

<img width="377" alt="image" src="https://github.com/user-attachments/assets/21404739-0a84-4879-b1c0-4618f4f73fa5">

</details>

<details>
<summary>WatchOS</summary>

<img width="292" alt="image" src="https://github.com/user-attachments/assets/f22db196-77c5-4ccb-be2c-33ddb0b342cb">

</details>

<details>
<summary>TVOS</summary>

<img width="1013" alt="image" src="https://github.com/user-attachments/assets/40ffb0ba-52fa-4201-b053-3686dca25038">

</details>

<details>
<summary>VisionOS</summary>

<img width="1113" alt="image" src="https://github.com/user-attachments/assets/62a3d273-51f3-40f9-b0ab-ac9f55046718">

</details>

## Features

- High-performance rendering using SwiftUI Canvas for smooth, responsive charts
- Optimized drawing algorithms for handling large datasets efficiently
- Candlestick chart with customizable appearance
- Support for multiple technical indicators (MA, MACD, RSI, Bollinger Bands, etc.)
- Scrollable and zoomable chart interface with fluid interactions
- Customizable legends and axes
- Support for both primary and secondary chart areas
- Designed for optimal performance across iOS, macOS, watchOS, tvOS, and visionOS

## Performance

Swift Trading View is built with performance in mind:

- **SwiftUI Canvas**: Utilizes SwiftUI's Canvas for high-performance, low-level drawing operations. This allows for smooth rendering of complex charts with thousands of data points.
- **Optimized Algorithms**: Implements efficient algorithms for calculating and rendering technical indicators, ensuring rapid updates even with large datasets.
- **Lazy Loading**: Employs lazy loading techniques to render only the visible portion of the chart, significantly reducing memory usage and improving performance.
- **Smooth Scrolling and Zooming**: Optimized for fluid interactions, providing a responsive user experience even when navigating through extensive historical data.

## Platform Support

Swift Trading View consists of two main components with different platform support:

### SwiftTA Wrapper

The SwiftTA wrapper, which provides the core technical analysis calculations, supports:

- iOS 12.0+
- macOS 10.13+
- watchOS 4.0+
- tvOS 12.0+
- visionOS 1.0+

### TradingView Component

The TradingView component, which provides the interactive chart interface, supports:

- iOS 16.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+
- visionOS 1.0+

Please note that while the SwiftTA wrapper can be used on a wider range of platform versions, the full TradingView component requires the more recent OS versions due to its use of advanced SwiftUI features.

## Installation

### Swift Package Manager

You can install Swift Trading View using the [Swift Package Manager](https://swift.org/package-manager/). Add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/sergeykhliustin/swift-trading-view.git", from: "1.0.0")
]
```

Alternatively, in Xcode, go to File > Swift Packages > Add Package Dependency and enter the repository URL:

```
https://github.com/sergeykhliustin/swift-trading-view.git
```

## Usage

Here's a basic example of how to use Swift Trading View in your SwiftUI application:

```swift
import SwiftUI
import SwiftTradingView

struct ContentView: View {
    var body: some View {
        TradingView(
            data: data,
            primaryContent: [
                Candles(),
                MAIndicator(),
                BBIndicator(),
            ],
            secondaryContent: [
                MACDIndicator(),
                RSIIndicator()
            ]
        )
    }
}
```

Whole interface provides default parameters, but you can customize them all.


This will create a high-performance trading view with candlesticks, Moving Average (MA), Bollinger Bands (BB) in the primary chart area, and MACD and RSI indicators in the secondary chart area.

## Customization

Swift Trading View offers extensive customization options. Here are a few examples:

### Customizing Indicators

You can customize individual indicators when adding them to the chart:

```swift
MAIndicator(
    periods: [
        .init(value: 7, color: .yellow),
        .init(value: 25, color: .blue),
        .init(value: 99, color: .red)
    ],
    lineWidth: 2
)
```

### Adjusting Chart Appearance

You can adjust various aspects of the chart's appearance:

```swift
TradingView(
    data: data,
    candleWidth: 4...30,
    candleSpacing: 1,
    scrollTrailingInset: 50,
    primaryContentHeight: 400,
    secondaryContentHeight: 150,
    secondaryContentSpacing: 10,
    // ... other parameters ...
)
```

### Customize Axis

Simply implement `Axis` protocol and provide your implementation as a param to `TradingView.xAxis` and `TradingView.yAxis`

### Customize Indicators

Implement your own indicator with conformance to `Content` protocol and pass it as `TradingView.primaryContent` or `TradingView.secondaryContent`

## Contributing

Contributions to Swift Trading View are welcome! Please feel free to submit a Pull Request.
