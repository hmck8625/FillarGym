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
        .accentColor(DesignSystem.Colors.secondary)
        .preferredColorScheme(.light)
        .onAppear {
            // Tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DesignSystem.Colors.surface)
            appearance.shadowColor = UIColor(DesignSystem.Colors.shadowLight)
            
            // Selected item color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DesignSystem.Colors.secondary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DesignSystem.Colors.secondary)
            ]
            
            // Normal item color
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DesignSystem.Colors.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(DesignSystem.Colors.textSecondary)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}