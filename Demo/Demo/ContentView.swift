import SwiftUI
import SwiftTradingView

struct ContentView: View {
    let data = CandleData.generateSampleData(count: 10000)
    var body: some View {
        TradingView(
            data: data, 
            primaryContentHeight: 100,
            primaryContent: [
                Candles(),
                MAIndicator(),
            ],
            secondaryContent: [
                RSIIndicator(),
                MACDIndicator(),
                KDJIndicator()
            ]
        )
    }
}

#Preview {
    ContentView()
}
