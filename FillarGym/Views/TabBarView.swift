import SwiftUI

struct TabBarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("ホーム")
                    }
                    .tag(0)
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("履歴")
                    }
                    .tag(1)
                
                AnalysisView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("分析")
                    }
                    .tag(2)
                
                StaticSettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("設定")
                    }
                    .tag(3)
            }
            .accentColor(DesignSystem.Colors.secondary)
            .preferredColorScheme(.light)
            
            // Custom active tab indicator
            VStack {
                Spacer()
                
                HStack {
                    ForEach(0..<4, id: \.self) { index in
                        VStack {
                            Rectangle()
                                .fill(selectedTab == index ? DesignSystem.Colors.secondary : Color.clear)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                            
                            Spacer()
                                .frame(height: 46) // Tab bar height minus indicator
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.clear)
                .allowsHitTesting(false) // タッチを下のTabViewに通す
            }
        }
        .onAppear {
            // Tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DesignSystem.Colors.surface)
            appearance.shadowColor = UIColor.clear // 境界線を削除
            appearance.shadowImage = UIImage() // 境界線を完全に削除
            
            // Selected item color with enhanced styling
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DesignSystem.Colors.secondary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DesignSystem.Colors.secondary),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
            
            // Normal item color
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DesignSystem.Colors.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(DesignSystem.Colors.textSecondary),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}