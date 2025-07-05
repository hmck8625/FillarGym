import SwiftUI
import CoreData

struct SafeSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingPremiumSheet = false
    @State private var monthlyGoal: Int = 10
    @State private var detectionSensitivity: Int = 1
    @State private var selectedLanguage: String = "ja"
    @State private var notificationEnabled: Bool = true
    @State private var isPremium: Bool = false
    
    var body: some View {
        List {
            // プロフィール・プラン情報
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("FillarGym")
                            .font(.headline)
                        Text(isPremium ? "Premium会員" : "Free会員")
                            .font(.caption)
                            .foregroundColor(isPremium ? .orange : .gray)
                    }
                    
                    Spacer()
                    
                    if !isPremium {
                        Button("アップグレード") {
                            showingPremiumSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            // 目標設定
            Section("目標設定") {
                HStack {
                    Text("月間目標録音数")
                    Spacer()
                    Stepper("\(monthlyGoal)回", value: $monthlyGoal, in: 1...100)
                        .onChange(of: monthlyGoal) { _, newValue in
                            saveSettings()
                        }
                }
            }
            
            // API設定
            Section("API設定") {
                NavigationLink("OpenAI APIキー") {
                    APIKeySettingsView()
                }
            }
            
            // フィラー語設定
            Section("フィラー語設定") {
                NavigationLink("検出するフィラー語") {
                    SimpleFillerWordsView()
                }
                
                VStack(alignment: .leading) {
                    Text("検出感度")
                    Picker("検出感度", selection: $detectionSensitivity) {
                        Text("低").tag(0)
                        Text("中").tag(1)
                        Text("高").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: detectionSensitivity) { _, newValue in
                        saveSettings()
                    }
                }
                
                Picker("言語", selection: $selectedLanguage) {
                    Text("日本語").tag("ja")
                    Text("English").tag("en")
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    saveSettings()
                }
            }
            
            // 通知設定
            Section("通知") {
                Toggle("練習リマインダー", isOn: $notificationEnabled)
                    .onChange(of: notificationEnabled) { _, newValue in
                        saveSettings()
                    }
            }
            
            // データ管理
            Section("データ管理") {
                NavigationLink("録音データ管理") {
                    DataManagementView()
                }
                
                if isPremium {
                    Button("データをエクスポート") {
                        // エクスポート機能
                    }
                }
            }
            
            // ヘルプ・サポート
            Section("ヘルプ・サポート") {
                NavigationLink("使い方ガイド") {
                    SimpleHelpView()
                }
                
                NavigationLink("お問い合わせ") {
                    SimpleContactView()
                }
            }
            
            // アプリ情報
            Section("アプリ情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("設定")
        .sheet(isPresented: $showingPremiumSheet) {
            SimplePremiumUpgradeView()
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        
        do {
            let userSettings = try viewContext.fetch(request)
            if let settings = userSettings.first {
                monthlyGoal = Int(settings.monthlyGoal)
                detectionSensitivity = Int(settings.detectionSensitivity)
                selectedLanguage = settings.language ?? "ja"
                notificationEnabled = settings.notificationEnabled
                isPremium = settings.isPremium
                print("✅ Settings loaded successfully")
            } else {
                // デフォルト設定で新規作成
                createDefaultSettings()
            }
        } catch {
            print("❌ Failed to load settings: \(error)")
            // エラー時はデフォルト値を使用
        }
    }
    
    private func createDefaultSettings() {
        let newSettings = UserSettings(context: viewContext)
        newSettings.monthlyGoal = Int16(monthlyGoal)
        newSettings.detectionSensitivity = Int16(detectionSensitivity)
        newSettings.language = selectedLanguage
        newSettings.notificationEnabled = notificationEnabled
        newSettings.isPremium = isPremium
        newSettings.updatedAt = Date()
        
        do {
            try viewContext.save()
            print("✅ Default settings created")
        } catch {
            print("❌ Failed to create default settings: \(error)")
        }
    }
    
    private func saveSettings() {
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        
        do {
            let userSettings = try viewContext.fetch(request)
            let settings = userSettings.first ?? UserSettings(context: viewContext)
            
            settings.monthlyGoal = Int16(monthlyGoal)
            settings.detectionSensitivity = Int16(detectionSensitivity)
            settings.language = selectedLanguage
            settings.notificationEnabled = notificationEnabled
            settings.isPremium = isPremium
            settings.updatedAt = Date()
            
            try viewContext.save()
            print("✅ Settings saved successfully")
        } catch {
            print("❌ Failed to save settings: \(error)")
        }
    }
}

// MARK: - Simple Helper Views

struct SimpleFillerWordsView: View {
    var body: some View {
        List {
            Section("デフォルトフィラー語") {
                Text("えー、あー、その、あの、えっと、まあ、なんか、ちょっと、やっぱり")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section("カスタムフィラー語") {
                Text("カスタムフィラー語機能は今後実装予定です")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("フィラー語設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SimpleHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("FillarGymの使い方")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. ホーム画面で「録音開始」をタップ")
                    Text("2. 1-10分程度話す内容を録音")
                    Text("3. 録音停止後、自動で分析開始")
                    Text("4. 分析結果を確認して改善点をチェック")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("使い方ガイド")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SimpleContactView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("お問い合わせ")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("ご質問やご要望がございましたら、\nアプリストアのレビューにてお聞かせください。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("お問い合わせ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SimplePremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Premium機能")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 15) {
                    SimpleFeatureRow(icon: "infinity", title: "無制限分析", description: "月の分析回数制限なし")
                    SimpleFeatureRow(icon: "chart.bar.doc.horizontal", title: "詳細レポート", description: "高度な統計と分析")
                    SimpleFeatureRow(icon: "icloud.and.arrow.down", title: "データエクスポート", description: "PDF・CSV形式で出力")
                }
                .padding()
                
                VStack(spacing: 15) {
                    Text("¥480/月")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Button("Premiumにアップグレード") {
                        // 課金処理（今後実装）
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SimpleFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}