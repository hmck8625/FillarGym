import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: UserSettings.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    ) private var userSettings: FetchedResults<UserSettings>
    
    @State private var showingPremiumSheet = false
    
    private var settings: UserSettings {
        if let existingSettings = userSettings.first {
            return existingSettings
        } else {
            let newSettings = UserSettings(context: viewContext)
            // デフォルト値を設定
            newSettings.monthlyGoal = 10
            newSettings.detectionSensitivity = 1
            newSettings.language = "ja"
            newSettings.notificationEnabled = true
            newSettings.isPremium = false
            newSettings.updatedAt = Date()
            
            do {
                try viewContext.save()
                print("✅ UserSettings created successfully")
            } catch {
                print("❌ Failed to create UserSettings: \(error)")
            }
            return newSettings
        }
    }
    
    var body: some View {
        List {
                // プロフィール・プラン情報
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("FillarGym")
                                .font(.headline)
                            Text(settings.isPremium ? "Premium会員" : "Free会員")
                                .font(.caption)
                                .foregroundColor(settings.isPremium ? .orange : .gray)
                        }
                        
                        Spacer()
                        
                        if !settings.isPremium {
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
                        Stepper("\(settings.monthlyGoal)回", value: Binding(
                            get: { Int(settings.monthlyGoal) },
                            set: { settings.monthlyGoal = Int16($0); saveSettings() }
                        ), in: 1...100)
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
                        FillerWordsSettingsView(settings: settings)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("検出感度")
                        Picker("検出感度", selection: Binding(
                            get: { Int(settings.detectionSensitivity) },
                            set: { settings.detectionSensitivity = Int16($0); saveSettings() }
                        )) {
                            Text("低").tag(0)
                            Text("中").tag(1)
                            Text("高").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Picker("言語", selection: Binding(
                        get: { settings.language ?? "ja" },
                        set: { settings.language = $0; saveSettings() }
                    )) {
                        Text("日本語").tag("ja")
                        Text("English").tag("en")
                    }
                }
                
                // 通知設定
                Section("通知") {
                    Toggle("練習リマインダー", isOn: Binding(
                        get: { settings.notificationEnabled },
                        set: { settings.notificationEnabled = $0; saveSettings() }
                    ))
                }
                
                // データ管理
                Section("データ管理") {
                    NavigationLink("録音データ管理") {
                        DataManagementView()
                    }
                    
                    if settings.isPremium {
                        Button("データをエクスポート") {
                            // エクスポート機能
                        }
                    }
                }
                
                // ヘルプ・サポート
                Section("ヘルプ・サポート") {
                    NavigationLink("使い方ガイド") {
                        HelpView()
                    }
                    
                    NavigationLink("お問い合わせ") {
                        ContactView()
                    }
                    
                    NavigationLink("プライバシーポリシー") {
                        PrivacyPolicyView()
                    }
                    
                    NavigationLink("利用規約") {
                        TermsOfServiceView()
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
            PremiumUpgradeView()
        }
    }
    
    private func saveSettings() {
        settings.updatedAt = Date()
        do {
            try viewContext.save()
            print("✅ Settings saved successfully")
        } catch {
            print("❌ Failed to save settings: \(error)")
        }
    }
}

// これらのビューは別ファイルで実装済み

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HelpSection(
                    title: "基本的な使い方",
                    icon: "mic.circle.fill",
                    steps: [
                        "ホーム画面で「録音開始」ボタンをタップ",
                        "話したい内容を1-10分程度録音",
                        "録音停止後、自動で分析が開始されます",
                        "分析結果を確認して改善点をチェック"
                    ]
                )
                
                HelpSection(
                    title: "分析結果の見方",
                    icon: "chart.bar.fill",
                    steps: [
                        "フィラー語数: 「えー」「あー」などの総数",
                        "フィラー率: 1分あたりのフィラー語数",
                        "改善率: 前回との比較での改善度",
                        "発話速度: 1分あたりの語数"
                    ]
                )
                
                HelpSection(
                    title: "上達のコツ",
                    icon: "lightbulb.fill",
                    steps: [
                        "週に3回程度の定期的な練習",
                        "話す内容を事前に整理する",
                        "フィラー語の代わりに間を取る",
                        "進捗グラフで改善を確認"
                    ]
                )
                
                HelpSection(
                    title: "Premium機能",
                    icon: "star.fill",
                    steps: [
                        "月間分析回数無制限",
                        "詳細な統計レポート",
                        "データのエクスポート機能",
                        "高度なパーソナライズ分析"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("使い方ガイド")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSection: View {
    let title: String
    let icon: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(width: 20, alignment: .leading)
                        Text(step)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ContactView: View {
    var body: some View {
        Text("お問い合わせ画面")
            .navigationTitle("お問い合わせ")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("プライバシーポリシー")
            .navigationTitle("プライバシーポリシー")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("利用規約")
            .navigationTitle("利用規約")
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Premium機能")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 15) {
                    PremiumFeatureRow(icon: "infinity", title: "無制限分析", description: "月の分析回数制限なし")
                    PremiumFeatureRow(icon: "chart.bar.doc.horizontal", title: "詳細レポート", description: "高度な統計と分析")
                    PremiumFeatureRow(icon: "icloud.and.arrow.down", title: "データエクスポート", description: "PDF・CSV形式で出力")
                    PremiumFeatureRow(icon: "bell.badge", title: "優先サポート", description: "専用サポート窓口")
                }
                .padding()
                
                VStack(spacing: 15) {
                    Text("¥480/月")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Button("Premiumにアップグレード") {
                        // 課金処理
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("購入を復元") {
                        // 復元処理
                    }
                    .foregroundColor(.blue)
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

struct PremiumFeatureRow: View {
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