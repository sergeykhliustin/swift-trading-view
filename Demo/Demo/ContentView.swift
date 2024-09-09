import SwiftUI
import TradingView

struct ContentView: View {
    let data = CandleData.generateSampleData(count: 10000)
    var body: some View {
        TradingView(
            data: data, 
            primaryContent: [
                Candles(),
                MAIndicator(),
            ],
            secondaryContent: [
                RSIIndicator(),
                MACDIndicator()
            ]
        )
    }
}

#Preview {
    ContentView()
}

extension CandleData {
    static func generateSampleData(count: Int = 1000) -> [Self] {
        var items: [Self] = []
        let startTime = Date().timeIntervalSince1970 - Double(count * 60) // Start 1000 minutes ago
        var lastClose = Double.random(in: 100...200) // Start with a random price between 100 and 200

        for i in 0..<count {
            let time = startTime + Double(i * 60) // Increment by 1 minute each time
            let changePercent = Double.random(in: -0.02...0.02) // Random change between -2% and 2%
            let close = lastClose * (1 + changePercent)
            let open = lastClose
            let high = max(open, close) * Double.random(in: 1.0...1.01) // Slightly higher than open or close
            let low = min(open, close) * Double.random(in: 0.99...1.0) // Slightly lower than open or close

            let item = Self(
                time: time,
                open: open,
                close: close,
                high: high,
                low: low
            )

            items.append(item)
            lastClose = close
        }

        return items
    }
}
