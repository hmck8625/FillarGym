# FillarGym - Analytics実装ガイド

## Firebase Analytics セットアップ

### 1. Firebase Console設定
1. [Firebase Console](https://console.firebase.google.com/) でプロジェクト作成
2. iOS アプリを追加
3. `GoogleService-Info.plist` をダウンロード
4. Xcodeプロジェクトに追加

### 2. Podfile 設定
```ruby
# Podfile
target 'FillarGym' do
  use_frameworks!
  
  # Firebase Analytics
  pod 'FirebaseAnalytics'
  pod 'FirebaseCore'
end
```

### 3. App初期化
```swift
// FillarGymApp.swift
import SwiftUI
import FirebaseCore

@main
struct FillarGymApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 実装パターン

### Analytics Manager の作成
```swift
// Services/AnalyticsManager.swift
import Foundation
import FirebaseAnalytics

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - DAU/MAU 計測
    func trackAppSession() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    func trackAppBackground() {
        Analytics.logEvent("app_backgrounded", parameters: [
            "session_duration": getCurrentSessionDuration()
        ])
    }
    
    // MARK: - 画面遷移（維持率計測に重要）
    func trackScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    // MARK: - ボタンクリック計測
    func trackButtonClick(buttonName: String, screenName: String) {
        Analytics.logEvent("button_click", parameters: [
            "button_name": buttonName,
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - カスタムイベント
    func trackCustomEvent(eventName: String, parameters: [String: Any] = [:]) {
        var params = parameters
        params["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        params["platform"] = "iOS"
        
        Analytics.logEvent(eventName, parameters: params)
    }
    
    // MARK: - ユーザープロパティ設定
    func setUserProperty(value: String, forName property: String) {
        Analytics.setUserProperty(value, forName: property)
    }
    
    // MARK: - FillarGym特化イベント
    func trackRecordingStarted() {
        Analytics.logEvent("recording_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackRecordingCompleted(duration: Double, fillerCount: Int) {
        Analytics.logEvent("recording_completed", parameters: [
            "duration_seconds": duration,
            "filler_count": fillerCount,
            "success": true
        ])
    }
    
    func trackAnalysisStarted(sourceType: String) {
        Analytics.logEvent("analysis_started", parameters: [
            "source_type": sourceType // "recording" or "file_upload"
        ])
    }
    
    func trackAnalysisCompleted(
        fillerCount: Int,
        fillerRate: Double,
        duration: Double,
        language: String
    ) {
        Analytics.logEvent("analysis_completed", parameters: [
            "filler_count": fillerCount,
            "filler_rate": fillerRate,
            "audio_duration": duration,
            "language": language,
            "success": true
        ])
    }
    
    func trackCustomFillerAdded(word: String) {
        Analytics.logEvent("custom_filler_added", parameters: [
            "word_length": word.count,
            "language": getCurrentLanguage()
        ])
    }
    
    func trackDefaultFillerToggled(word: String, enabled: Bool) {
        Analytics.logEvent("default_filler_toggled", parameters: [
            "word": word,
            "enabled": enabled,
            "language": getCurrentLanguage()
        ])
    }
    
    func trackFileUpload(fileSize: Int64, duration: Double, format: String) {
        Analytics.logEvent("file_uploaded", parameters: [
            "file_size_mb": Double(fileSize) / (1024 * 1024),
            "duration_seconds": duration,
            "format": format
        ])
    }
    
    func trackSettingsChanged(settingName: String, newValue: Any) {
        Analytics.logEvent("settings_changed", parameters: [
            "setting_name": settingName,
            "new_value": String(describing: newValue)
        ])
    }
    
    func trackError(errorType: String, errorMessage: String, location: String) {
        Analytics.logEvent("error_occurred", parameters: [
            "error_type": errorType,
            "error_message": errorMessage,
            "location": location,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }
    
    // MARK: - Helper Methods
    private func getCurrentSessionDuration() -> TimeInterval {
        // セッション開始時刻を記録し、現在時刻との差を返す
        // UserDefaultsやプロパティで管理
        return 0 // 実装が必要
    }
    
    private func getCurrentLanguage() -> String {
        return UserDefaults.standard.string(forKey: "app_language") ?? "ja"
    }
}
```

## View での実装例

### 1. 画面遷移計測
```swift
// Views/RecordingView.swift
struct RecordingView: View {
    private let analytics = AnalyticsManager.shared
    
    var body: some View {
        VStack {
            // UI コンテンツ
        }
        .onAppear {
            analytics.trackScreenView(
                screenName: "recording_view",
                screenClass: "RecordingView"
            )
        }
    }
}

// Views/SettingsView.swift
struct StaticSettingsView: View {
    private let analytics = AnalyticsManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // 設定項目
            }
        }
        .onAppear {
            analytics.trackScreenView(
                screenName: "settings_view", 
                screenClass: "StaticSettingsView"
            )
        }
    }
}
```

### 2. ボタンクリック計測
```swift
// ボタンクリック例
Button("録音開始") {
    analytics.trackButtonClick(
        buttonName: "start_recording",
        screenName: "recording_view"
    )
    analytics.trackRecordingStarted()
    
    // 録音開始処理
    startRecording()
}

Button("このファイルを分析") {
    analytics.trackButtonClick(
        buttonName: "analyze_file",
        screenName: "file_info_view"
    )
    analytics.trackAnalysisStarted(sourceType: "file_upload")
    
    // 分析開始処理
    startAnalysis()
}

// NavigationLink のクリック計測
NavigationLink("検出するフィラー語") {
    FillerWordsListView()
}
.onTapGesture {
    analytics.trackButtonClick(
        buttonName: "filler_settings_navigation",
        screenName: "settings_view"
    )
}
```

### 3. カスタムフィラー語管理の計測
```swift
// FillerWordsListView.swift
private func addCustomWord() {
    let trimmedWord = newWord.trimmingCharacters(in: .whitespaces)
    guard !trimmedWord.isEmpty, !customWords.contains(trimmedWord) else {
        newWord = ""
        return
    }
    
    // 分析計測
    analytics.trackCustomFillerAdded(word: trimmedWord)
    
    customWords.append(trimmedWord)
    saveCustomWords()
    newWord = ""
}

private func disableDefaultWord(_ word: String) {
    analytics.trackDefaultFillerToggled(word: word, enabled: false)
    
    if !disabledDefaultWords.contains(word) {
        disabledDefaultWords.append(word)
        saveCustomWords()
    }
}
```

### 4. 分析完了の計測
```swift
// AnalysisManager.swift
private func saveAnalysisResults(_ response: FillerAnalysisResponse, for audioSession: AudioSession, context: NSManagedObjectContext) {
    // ... 既存の保存処理
    
    // 分析完了を計測
    AnalyticsManager.shared.trackAnalysisCompleted(
        fillerCount: Int(response.total_filler_count),
        fillerRate: response.filler_rate_per_minute,
        duration: audioSession.duration,
        language: userSettings?.language ?? "ja"
    )
    
    do {
        try context.save()
        completeAnalysis()
    } catch {
        AnalyticsManager.shared.trackError(
            errorType: "core_data_save_failed",
            errorMessage: error.localizedDescription,
            location: "AnalysisManager.saveAnalysisResults"
        )
        handleError(error)
    }
}
```

### 5. エラー計測
```swift
// 各エラーハンドリング箇所で
private func loadUserSettings() {
    // ... 既存のコード
    
    do {
        let settings = try viewContext.fetch(request)
        // ...
    } catch {
        analytics.trackError(
            errorType: "user_settings_load_failed",
            errorMessage: error.localizedDescription,
            location: "FillerWordsListView.loadUserSettings"
        )
        // ...
    }
}
```

## ユーザープロパティ設定

### アプリ起動時の設定
```swift
// ContentView.swift または App.swift
struct ContentView: View {
    private let analytics = AnalyticsManager.shared
    
    var body: some View {
        TabView {
            // タブ内容
        }
        .onAppear {
            setupUserProperties()
            analytics.trackAppSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            analytics.trackAppBackground()
        }
    }
    
    private func setupUserProperties() {
        // ユーザー属性を設定
        analytics.setUserProperty(getCurrentLanguage(), forName: "user_language")
        analytics.setUserProperty(getAppVersion(), forName: "app_version")
        analytics.setUserProperty(getDeviceModel(), forName: "device_model")
        
        // カスタムフィラー語の使用状況
        let customWordsCount = getCustomFillerWordsCount()
        analytics.setUserProperty(String(customWordsCount), forName: "custom_words_count")
    }
}
```

## Firebase Consoleでの確認方法

### 1. DAU/MAU
- **場所**: Analytics > Audiences > Overview
- **確認項目**: Active users (1日、7日、28日)

### 2. 維持率 (Retention)
- **場所**: Analytics > Retention
- **確認項目**: Day 1, Day 7, Day 30 retention

### 3. イベント発火数
- **場所**: Analytics > Events
- **確認項目**: 各カスタムイベントの発生回数

### 4. ボタンクリック数
- **場所**: Analytics > Events > button_click
- **フィルター**: button_name でフィルタリング可能

### 5. ユーザーフロー
- **場所**: Analytics > User journey
- **確認項目**: 画面遷移パターンの分析

## カスタムダッシュボード設定

### 重要な指標をまとめたダッシュボード
```
1. DAU/MAU トレンド
2. 録音完了率 (recording_completed / recording_started)
3. 分析成功率 (analysis_completed / analysis_started)
4. カスタムフィラー語利用率
5. エラー発生率
6. 画面別滞在時間
7. ユーザー維持率
```

## データエクスポート

### BigQuery連携（無料枠あり）
```sql
-- 日次アクティブユーザー
SELECT
  event_date,
  COUNT(DISTINCT user_pseudo_id) as dau
FROM `your_project.analytics_xxxxx.events_*`
WHERE event_name = 'session_start'
GROUP BY event_date
ORDER BY event_date DESC

-- ボタンクリック分析
SELECT
  event_date,
  event_params.value.string_value as button_name,
  COUNT(*) as click_count
FROM `your_project.analytics_xxxxx.events_*`,
UNNEST(event_params) as event_params
WHERE event_name = 'button_click'
  AND event_params.key = 'button_name'
GROUP BY event_date, button_name
ORDER BY event_date DESC, click_count DESC
```

## プライバシー対応

### ユーザー同意の実装
```swift
struct AnalyticsConsentView: View {
    @AppStorage("analytics_consent") private var analyticsConsent = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("アプリ改善のためのデータ利用について")
                .font(.headline)
            
            Text("アプリの使用状況を分析し、より良いサービスを提供するため、匿名化されたデータを収集させていただきます。")
                .multilineTextAlignment(.center)
            
            Toggle("データ収集に同意する", isOn: $analyticsConsent)
                .onChange(of: analyticsConsent) { consent in
                    Analytics.setAnalyticsCollectionEnabled(consent)
                    UserDefaults.standard.set(consent, forKey: "analytics_consent")
                }
        }
        .padding()
        .onAppear {
            Analytics.setAnalyticsCollectionEnabled(analyticsConsent)
        }
    }
}
```

これで、DAU/MAU、維持率、特定イベントの発火数、ボタンクリック数などが全て無料で計測できます！Firebase Consoleで リアルタイムで確認でき、詳細な分析も可能です。