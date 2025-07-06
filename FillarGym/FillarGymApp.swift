//
//  FillarGymApp.swift
//  FillarGym
//
//  Created by 浜崎大輔 on 2025/07/05.
//

import SwiftUI
// import FirebaseCore // Temporarily disabled

@main
struct FillarGymApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        // Firebase初期化
        // FirebaseApp.configure() // Temporarily disabled
        
        // Analytics初期化
        setupAnalytics()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    AnalyticsManager.shared.startSession()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    AnalyticsManager.shared.trackAppBackground()
                }
        }
    }
    
    private func setupAnalytics() {
        // Analyticsを常時有効化（ユーザー設定に関係なく）
        AnalyticsManager.shared.setEnabled(true)
        UserDefaults.standard.set(true, forKey: "analytics_enabled")
        
        // ユーザープロパティの設定
        setupUserProperties()
    }
    
    private func setupUserProperties() {
        let analytics = AnalyticsManager.shared
        
        // アプリバージョン
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            analytics.setUserProperty(value: appVersion, forName: "app_version")
        }
        
        // デバイス情報
        analytics.setUserProperty(value: UIDevice.current.model, forName: "device_model")
        analytics.setUserProperty(value: UIDevice.current.systemVersion, forName: "ios_version")
        
        // 言語設定
        let language = UserDefaults.standard.string(forKey: "app_language") ?? "ja"
        analytics.setUserProperty(value: language, forName: "user_language")
    }
}
