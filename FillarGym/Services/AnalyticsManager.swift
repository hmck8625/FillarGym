import Foundation

// Firebase Analytics - 完全版
import FirebaseCore
import FirebaseAnalytics

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Configuration
    private var isEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "analytics_enabled")
    }
    
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        // Firebase Analytics有効/無効設定
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
    
    // MARK: - DAU/MAU 計測
    func trackAppSession() {
        guard isEnabled else { return }
        print("📊 Analytics: App session started")
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    func trackAppBackground() {
        guard isEnabled else { return }
        print("📊 Analytics: App backgrounded")
        // Analytics.logEvent("app_backgrounded", parameters: [
        //     "session_duration": getCurrentSessionDuration()
        // ])
    }
    
    // MARK: - 画面遷移（維持率計測に重要）
    func trackScreenView(screenName: String, screenClass: String) {
        guard isEnabled else { return }
        print("📊 Analytics: Screen view - \(screenName) (\(screenClass))")
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    // MARK: - ボタンクリック計測
    func trackButtonClick(buttonName: String, screenName: String) {
        guard isEnabled else { return }
        print("📊 Analytics: Button click - \(buttonName) on \(screenName)")
        // Analytics.logEvent("button_click", parameters: [
        //     "button_name": buttonName,
        //     "screen_name": screenName,
        //     "timestamp": Date().timeIntervalSince1970
        // ])
    }
    
    // MARK: - カスタムイベント
    func trackCustomEvent(eventName: String, parameters: [String: Any] = [:]) {
        guard isEnabled else { return }
        print("📊 Analytics: Custom event - \(eventName) with params: \(parameters)")
        var params = parameters
        params["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        params["platform"] = "iOS"
        Analytics.logEvent(eventName, parameters: params)
    }
    
    // MARK: - ユーザープロパティ設定
    func setUserProperty(value: String, forName property: String) {
        guard isEnabled else { return }
        print("📊 Analytics: User property - \(property): \(value)")
        Analytics.setUserProperty(value, forName: property)
    }
    
    // MARK: - FillarGym特化イベント
    func trackRecordingStarted() {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "recording_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackRecordingCompleted(duration: Double, fillerCount: Int) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "recording_completed", parameters: [
            "duration_seconds": duration,
            "filler_count": fillerCount,
            "success": true
        ])
    }
    
    func trackAnalysisStarted(sourceType: String) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "analysis_started", parameters: [
            "source_type": sourceType // "recording" or "file_upload"
        ])
    }
    
    func trackAnalysisCompleted(
        fillerCount: Int,
        fillerRate: Double,
        duration: Double,
        language: String
    ) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "analysis_completed", parameters: [
            "filler_count": fillerCount,
            "filler_rate": fillerRate,
            "audio_duration": duration,
            "language": language,
            "success": true
        ])
    }
    
    func trackCustomFillerAdded(word: String) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "custom_filler_added", parameters: [
            "word_length": word.count,
            "language": getCurrentLanguage()
        ])
    }
    
    func trackDefaultFillerToggled(word: String, enabled: Bool) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "default_filler_toggled", parameters: [
            "word": word,
            "enabled": enabled,
            "language": getCurrentLanguage()
        ])
    }
    
    func trackFileUpload(fileSize: Int64, duration: Double, format: String) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "file_uploaded", parameters: [
            "file_size_mb": Double(fileSize) / (1024 * 1024),
            "duration_seconds": duration,
            "format": format
        ])
    }
    
    func trackSettingsChanged(settingName: String, newValue: Any) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "settings_changed", parameters: [
            "setting_name": settingName,
            "new_value": String(describing: newValue)
        ])
    }
    
    func trackError(errorType: String, errorMessage: String, location: String) {
        guard isEnabled else { return }
        trackCustomEvent(eventName: "error_occurred", parameters: [
            "error_type": errorType,
            "error_message": errorMessage,
            "location": location,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }
    
    // MARK: - Helper Methods
    private func getCurrentSessionDuration() -> TimeInterval {
        // セッション開始時刻を記録し、現在時刻との差を返す
        let sessionStart = UserDefaults.standard.double(forKey: "session_start_time")
        guard sessionStart > 0 else { return 0 }
        return Date().timeIntervalSince1970 - sessionStart
    }
    
    private func getCurrentLanguage() -> String {
        return UserDefaults.standard.string(forKey: "app_language") ?? "ja"
    }
    
    func startSession() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "session_start_time")
        trackAppSession()
    }
}