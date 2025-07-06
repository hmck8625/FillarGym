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
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // プロフィール・プラン情報
                    profileSection
                    
                    // 目標設定
                    goalSection
                    
                    // API設定
                    apiSection
                    
                    // フィラー語設定
                    fillerWordsSection
                    
                    // 通知設定
                    notificationSection
                    
                    // データ管理
                    dataManagementSection
                    
                    // ヘルプ・サポート
                    helpSupportSection
                    
                    // アプリ情報
                    appInfoSection
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.background,
                        DesignSystem.Colors.surfaceElevated.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingPremiumSheet) {
            ModernPremiumUpgradeView()
        }
    }
    
    // MARK: - Section Views
    private var profileSection: some View {
        ModernCard(elevation: .medium, padding: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: DesignSystem.IconSize.extraLarge, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("FillarGym")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    StatusBadge(
                        text: settings.isPremium ? "Premium会員" : "Free会員",
                        status: settings.isPremium ? .warning : .neutral
                    )
                }
                
                Spacer()
                
                if !settings.isPremium {
                    PillButton(
                        title: "アップグレード",
                        icon: "star.fill",
                        size: .medium,
                        variant: .primary
                    ) {
                        showingPremiumSheet = true
                    }
                }
            }
        }
        .pressAnimation()
    }
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("目標設定", icon: "target")
            
            ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("月間目標録音数")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("毎月の録音目標を設定")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("\(settings.monthlyGoal)回")
                            .font(DesignSystem.Typography.numberMedium)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    Stepper("", value: Binding(
                        get: { Int(settings.monthlyGoal) },
                        set: { settings.monthlyGoal = Int16($0); saveSettings() }
                    ), in: 1...100)
                    .labelsHidden()
                }
            }
        }
    }
    
    private var apiSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("API設定", icon: "key")
            
            NavigationLink(destination: APIKeySettingsView()) {
                ModernSettingsRow(
                    title: "OpenAI APIキー",
                    subtitle: "音声分析のためのAPIキー設定",
                    icon: "key.fill",
                    iconColor: DesignSystem.Colors.warning
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var fillerWordsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("フィラー語設定", icon: "waveform")
            
            VStack(spacing: DesignSystem.Spacing.md) {
                NavigationLink(destination: FillerWordsSettingsView(settings: settings)) {
                    ModernSettingsRow(
                        title: "検出するフィラー語",
                        subtitle: "カスタムフィラー語の管理",
                        icon: "text.bubble",
                        iconColor: DesignSystem.Colors.accent
                    )
                }
                .buttonStyle(.plain)
                
                ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("検出感度")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
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
                }
                
                ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("言語設定")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Picker("言語", selection: Binding(
                            get: { settings.language ?? "ja" },
                            set: { settings.language = $0; saveSettings() }
                        )) {
                            Text("日本語").tag("ja")
                            Text("English").tag("en")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("通知設定", icon: "bell")
            
            ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("練習リマインダー")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("定期的な練習を促すリマインダー")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { settings.notificationEnabled },
                        set: { settings.notificationEnabled = $0; saveSettings() }
                    ))
                    .labelsHidden()
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("データ管理", icon: "externaldrive")
            
            VStack(spacing: DesignSystem.Spacing.md) {
                NavigationLink(destination: DataManagementView()) {
                    ModernSettingsRow(
                        title: "録音データ管理",
                        subtitle: "保存された録音データの管理",
                        icon: "folder",
                        iconColor: DesignSystem.Colors.secondary
                    )
                }
                .buttonStyle(.plain)
                
                if settings.isPremium {
                    ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                        PillButton(
                            title: "データをエクスポート",
                            icon: "square.and.arrow.up",
                            size: .medium,
                            variant: .outline
                        ) {
                            // エクスポート機能
                        }
                    }
                }
            }
        }
    }
    
    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("ヘルプ・サポート", icon: "questionmark.circle")
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                NavigationLink(destination: ModernHelpView()) {
                    ModernSettingsRow(
                        title: "使い方ガイド",
                        subtitle: "アプリの基本的な使い方",
                        icon: "book",
                        iconColor: DesignSystem.Colors.primary
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: ContactView()) {
                    ModernSettingsRow(
                        title: "お問い合わせ",
                        subtitle: "サポートへのお問い合わせ",
                        icon: "envelope",
                        iconColor: DesignSystem.Colors.info
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    ModernSettingsRow(
                        title: "プライバシーポリシー",
                        subtitle: "個人情報の取り扱いについて",
                        icon: "hand.raised",
                        iconColor: DesignSystem.Colors.success
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: TermsOfServiceView()) {
                    ModernSettingsRow(
                        title: "利用規約",
                        subtitle: "サービス利用の規約",
                        icon: "doc.text",
                        iconColor: DesignSystem.Colors.textSecondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader("アプリ情報", icon: "info.circle")
            
            ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("バージョン")
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("現在のアプリバージョン")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(DesignSystem.Typography.numberMedium)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
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

struct ModernHelpView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                ModernHelpSection(
                    title: "基本的な使い方",
                    icon: "mic.circle.fill",
                    iconColor: DesignSystem.Colors.primary,
                    steps: [
                        "ホーム画面で「録音開始」ボタンをタップ",
                        "話したい内容を1-10分程度録音",
                        "録音停止後、自動で分析が開始されます",
                        "分析結果を確認して改善点をチェック"
                    ]
                )
                
                ModernHelpSection(
                    title: "分析結果の見方",
                    icon: "chart.bar.fill",
                    iconColor: DesignSystem.Colors.info,
                    steps: [
                        "フィラー語数: 「えー」「あー」などの総数",
                        "フィラー率: 1分あたりのフィラー語数",
                        "改善率: 前回との比較での改善度",
                        "発話速度: 1分あたりの語数"
                    ]
                )
                
                ModernHelpSection(
                    title: "上達のコツ",
                    icon: "lightbulb.fill",
                    iconColor: DesignSystem.Colors.warning,
                    steps: [
                        "週に3回程度の定期的な練習",
                        "話す内容を事前に整理する",
                        "フィラー語の代わりに間を取る",
                        "進捗グラフで改善を確認"
                    ]
                )
                
                ModernHelpSection(
                    title: "Premium機能",
                    icon: "star.fill",
                    iconColor: DesignSystem.Colors.accent,
                    steps: [
                        "月間分析回数無制限",
                        "詳細な統計レポート",
                        "データのエクスポート機能",
                        "高度なパーソナライズ分析"
                    ]
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.surfaceElevated.opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("使い方ガイド")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModernHelpSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let steps: [String]
    
    var body: some View {
        ModernCard(elevation: .medium, padding: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.large, weight: .semibold))
                        .foregroundColor(iconColor)
                    
                    Text(title)
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            Text("\(index + 1)")
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(iconColor)
                                .frame(width: 20, height: 20)
                                .background(iconColor.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.pill)
                                .frame(width: 20, alignment: .center)
                            
                            Text(step)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .pressAnimation()
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

struct ModernPremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    // ヘッダー
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text("Premium機能")
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("話し方改善をもっと効果的に")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // 機能一覧
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ModernPremiumFeatureRow(
                            icon: "infinity",
                            title: "無制限分析",
                            description: "月の分析回数制限なし",
                            iconColor: DesignSystem.Colors.primary
                        )
                        
                        ModernPremiumFeatureRow(
                            icon: "chart.bar.doc.horizontal",
                            title: "詳細レポート",
                            description: "高度な統計と分析",
                            iconColor: DesignSystem.Colors.info
                        )
                        
                        ModernPremiumFeatureRow(
                            icon: "icloud.and.arrow.down",
                            title: "データエクスポート",
                            description: "PDF・CSV形式で出力",
                            iconColor: DesignSystem.Colors.success
                        )
                        
                        ModernPremiumFeatureRow(
                            icon: "bell.badge",
                            title: "優先サポート",
                            description: "専用サポート窓口",
                            iconColor: DesignSystem.Colors.warning
                        )
                    }
                    
                    // 価格・購入
                    ModernCard(elevation: .high, padding: DesignSystem.Spacing.xl) {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            Text("¥480/月")
                                .font(DesignSystem.Typography.numberLarge.weight(.bold))
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            PillButton(
                                title: "Premiumにアップグレード",
                                icon: "star.fill",
                                size: .large,
                                variant: .primary
                            ) {
                                // 課金処理
                            }
                            
                            PillButton(
                                title: "購入を復元",
                                icon: "arrow.clockwise",
                                size: .medium,
                                variant: .ghost
                            ) {
                                // 復元処理
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.background,
                        DesignSystem.Colors.surfaceElevated.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

struct ModernPremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.large, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: DesignSystem.IconSize.extraLarge, height: DesignSystem.IconSize.extraLarge)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(description)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .pressAnimation()
    }
}

// MARK: - Modern Settings Row
struct ModernSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: DesignSystem.IconSize.large, height: DesignSystem.IconSize.large)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .pressAnimation()
    }
}