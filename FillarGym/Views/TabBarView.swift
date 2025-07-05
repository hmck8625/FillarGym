import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("履歴")
                }
            
            AnalysisView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("分析")
                }
            
            StaticSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
        }
        .accentColor(.blue)
    }
}