import SwiftUI
import CoreData

struct StaticSettingsView: View {
    @State private var showingPremiumSheet = false
    @State private var monthlyGoal: Int = 10
    @State private var detectionSensitivity: Int = 1
    @State private var selectedLanguage: String = "ja"
    @State private var notificationEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            List {
                // プロフィール・プラン情報
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("FillarGym")
                            .font(.headline)
                        Text("Free会員")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button("アップグレード") {
                        showingPremiumSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // 目標設定
            Section("目標設定") {
                HStack {
                    Text("月間目標録音数")
                    Spacer()
                    Stepper("\(monthlyGoal)回", value: $monthlyGoal, in: 1...50)
                }
            }
            
            
            // フィラー語設定
            Section("フィラー語設定") {
                NavigationLink("検出するフィラー語") {
                    FillerWordsListView()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("検出感度")
                        .font(.subheadline)
                    Picker("検出感度", selection: $detectionSensitivity) {
                        Text("低").tag(0)
                        Text("中").tag(1)
                        Text("高").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.vertical, 4)
                
                Picker("言語", selection: $selectedLanguage) {
                    Text("日本語").tag("ja")
                    Text("English").tag("en")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // 通知設定
            Section("通知") {
                Toggle("練習リマインダー", isOn: $notificationEnabled)
            }
            
            // データ管理
            Section("データ管理") {
                NavigationLink("録音データ管理") {
                    RecordingDataManagementView()
                }
            }
            
            // ヘルプ・サポート
            Section("ヘルプ・サポート") {
                NavigationLink("使い方ガイド") {
                    HelpGuideView()
                }
                
                NavigationLink("お問い合わせ") {
                    SettingsContactView()
                }
                
                NavigationLink("プライバシーポリシー") {
                    SettingsPrivacyPolicyView()
                }
            }
            
            // プライバシー・分析
            Section("プライバシー") {
                HStack {
                    Text("分析データ収集")
                    Spacer()
                    Text("有効")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("データ保護")
                    Spacer()
                    Text("ローカル処理")
                        .foregroundColor(.secondary)
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
                StaticPremiumView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FillerWordsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userSettings: UserSettings?
    @State private var customWords: [String] = []
    @State private var disabledDefaultWords: [String] = [] // 無効化されたデフォルト語
    @State private var newWord = ""
    @State private var showingAddAlert = false
    @State private var editingWord: String?
    @State private var editText = ""
    
    var body: some View {
        List {
            Section("デフォルトフィラー語（日本語）") {
                ForEach(UserSettings.defaultFillerWords(for: "ja"), id: \.self) { word in
                    HStack {
                        Text(word)
                            .foregroundColor(disabledDefaultWords.contains(word) ? .gray : .primary)
                        Spacer()
                        
                        if disabledDefaultWords.contains(word) {
                            Button(action: {
                                enableDefaultWord(word)
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        } else {
                            Button(action: {
                                disableDefaultWord(word)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
            
            Section("デフォルトフィラー語（English）") {
                ForEach(UserSettings.defaultFillerWords(for: "en"), id: \.self) { word in
                    HStack {
                        Text(word)
                            .foregroundColor(disabledDefaultWords.contains(word) ? .gray : .primary)
                        Spacer()
                        
                        if disabledDefaultWords.contains(word) {
                            Button(action: {
                                enableDefaultWord(word)
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        } else {
                            Button(action: {
                                disableDefaultWord(word)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
            
            Section {
                ForEach(customWords, id: \.self) { word in
                    HStack {
                        Text(word)
                        Spacer()
                        Button(action: {
                            editingWord = word
                            editText = word
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            removeCustomWord(word)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                Button(action: {
                    showingAddAlert = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("カスタムフィラー語を追加")
                            .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("カスタムフィラー語")
            } footer: {
                Text("独自のフィラー語を追加できます。口癖や特定の言葉を検出対象に設定しましょう。")
                    .font(.caption)
            }
            
            // 使用方法の説明
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 カスタムフィラー語について")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• あなたの口癖や特定の言葉を追加できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 「まじで」「やばい」「要するに」などがよく使われます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 追加したフィラー語は分析で自動検出されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("フィラー語設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserSettings()
        }
        .alert("新しいフィラー語を追加", isPresented: $showingAddAlert) {
            TextField("フィラー語を入力", text: $newWord)
            Button("追加") {
                addCustomWord()
            }
            Button("キャンセル", role: .cancel) {
                newWord = ""
            }
        } message: {
            Text("検出したいフィラー語を入力してください")
        }
        .alert("フィラー語を編集", isPresented: .constant(editingWord != nil)) {
            TextField("フィラー語を編集", text: $editText)
            Button("保存") {
                updateCustomWord()
            }
            Button("キャンセル", role: .cancel) {
                editingWord = nil
                editText = ""
            }
        } message: {
            Text("フィラー語を編集してください")
        }
    }
    
    private func loadUserSettings() {
        print("📋 FillerWordsListView: UserSettings読み込み開始")
        
        // メインスレッドで実行されているかチェック
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.loadUserSettings()
            }
            return
        }
        
        // Core Data操作をメインキューで実行
        viewContext.perform {
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            request.fetchLimit = 1 // パフォーマンス最適化
            
            do {
                let settings = try self.viewContext.fetch(request)
                print("📋 UserSettings検索結果: \(settings.count)件")
                
                // メインスレッドで状態更新
                DispatchQueue.main.async {
                    if let existingSettings = settings.first {
                        print("📋 既存UserSettings使用")
                        self.userSettings = existingSettings
                        self.customWords = existingSettings.activeCustomFillerWordsArray
                        self.disabledDefaultWords = existingSettings.disabledDefaultWordsArray
                        print("📋 カスタムフィラー語: \(self.customWords)")
                        print("📋 無効化デフォルト語: \(self.disabledDefaultWords)")
                    } else {
                        print("📋 新しいUserSettings作成")
                        self.createNewUserSettings()
                    }
                }
            } catch {
                print("❌ UserSettings読み込みエラー: \(error)")
                DispatchQueue.main.async {
                    self.userSettings = nil
                    self.customWords = []
                    self.disabledDefaultWords = []
                }
            }
        }
        
        print("📋 UserSettings読み込み完了")
    }
    
    private func createNewUserSettings() {
        viewContext.perform {
            let newSettings = UserSettings(context: self.viewContext)
            
            do {
                try self.viewContext.save()
                print("📋 新しいUserSettings保存成功")
                DispatchQueue.main.async {
                    self.userSettings = newSettings
                    self.customWords = []
                    self.disabledDefaultWords = []
                }
            } catch {
                print("❌ UserSettings保存エラー: \(error)")
                DispatchQueue.main.async {
                    self.userSettings = nil
                    self.customWords = []
                    self.disabledDefaultWords = []
                }
            }
        }
    }
    
    private func addCustomWord() {
        let trimmedWord = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmedWord.isEmpty, !customWords.contains(trimmedWord) else {
            newWord = ""
            return
        }
        
        customWords.append(trimmedWord)
        saveCustomWords()
        newWord = ""
    }
    
    private func removeCustomWord(_ word: String) {
        customWords.removeAll { $0 == word }
        saveCustomWords()
    }
    
    private func updateCustomWord() {
        guard let oldWord = editingWord else { return }
        let trimmedNewWord = editText.trimmingCharacters(in: .whitespaces)
        
        if !trimmedNewWord.isEmpty, !customWords.contains(trimmedNewWord) {
            if let index = customWords.firstIndex(of: oldWord) {
                customWords[index] = trimmedNewWord
                saveCustomWords()
            }
        }
        
        editingWord = nil
        editText = ""
    }
    
    private func saveCustomWords() {
        print("📋 カスタムフィラー語保存開始")
        
        guard let settings = userSettings else {
            print("❌ userSettingsがnil")
            return
        }
        
        // メインスレッドで実行
        if Thread.isMainThread {
            performSave(settings: settings)
        } else {
            DispatchQueue.main.async {
                self.performSave(settings: settings)
            }
        }
    }
    
    private func performSave(settings: UserSettings) {
        print("📋 保存開始 - カスタム語: \(customWords), 無効化語: \(disabledDefaultWords)")
        
        // 安全に値を設定
        let cleanCustomWords = customWords.filter { !$0.isEmpty && !$0.hasPrefix("DISABLED:") }
        let cleanDisabledWords = disabledDefaultWords.filter { !$0.isEmpty }
        
        // 段階的に設定
        let combinedWords = cleanCustomWords + cleanDisabledWords.map { "DISABLED:\($0)" }
        settings.customFillerWords = combinedWords.joined(separator: ", ")
        settings.updatedAt = Date()
        
        print("📋 保存データ: \(settings.customFillerWords ?? "nil")")
        
        do {
            try viewContext.save()
            print("📋 フィラー語設定保存成功")
        } catch {
            print("❌ フィラー語設定保存エラー: \(error)")
            // 失敗した場合は元の状態に戻す
            if let originalSettings = userSettings {
                customWords = originalSettings.activeCustomFillerWordsArray
                disabledDefaultWords = originalSettings.disabledDefaultWordsArray
            }
        }
    }
    
    private func disableDefaultWord(_ word: String) {
        print("📋 デフォルト語無効化: \(word)")
        if !disabledDefaultWords.contains(word) {
            disabledDefaultWords.append(word)
            saveCustomWords()
        }
    }
    
    private func enableDefaultWord(_ word: String) {
        print("📋 デフォルト語有効化: \(word)")
        disabledDefaultWords.removeAll { $0 == word }
        saveCustomWords()
    }
}

struct HelpGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsHelpSection(
                    title: "基本的な使い方",
                    icon: "mic.circle.fill",
                    steps: [
                        "ホーム画面で「録音開始」ボタンをタップ",
                        "話したい内容を1-10分程度録音",
                        "録音停止後、自動で分析が開始されます",
                        "分析結果を確認して改善点をチェック"
                    ]
                )
                
                SettingsHelpSection(
                    title: "分析結果の見方",
                    icon: "chart.bar.fill",
                    steps: [
                        "フィラー語数: 「えー」「あー」などの総数",
                        "フィラー率: 1分あたりのフィラー語数",
                        "改善率: 前回との比較での改善度",
                        "発話速度: 1分あたりの語数"
                    ]
                )
                
                SettingsHelpSection(
                    title: "上達のコツ",
                    icon: "lightbulb.fill",
                    steps: [
                        "週に3回程度の定期的な練習",
                        "話す内容を事前に整理する",
                        "フィラー語の代わりに間を取る",
                        "進捗グラフで改善を確認"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("使い方ガイド")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsHelpSection: View {
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

struct SettingsContactView: View {
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

struct SettingsPrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("プライバシーポリシー")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("FillarGymは、ユーザーのプライバシーを尊重し、個人情報の保護に努めています。")
                
                Text("収集する情報")
                    .font(.headline)
                    .padding(.top)
                
                Text("• 録音データ（デバイス内にのみ保存）\n• アプリの使用統計（匿名化）\n• クラッシュレポート\n• 機能利用パターン（改善目的）")
                
                Text("情報の利用目的")
                    .font(.headline)
                    .padding(.top)
                
                Text("• アプリの機能向上\n• ユーザー体験の最適化\n• バグの修正と安定性向上\n• 新機能開発の参考データ")
                
                Text("データの取り扱い")
                    .font(.headline)
                    .padding(.top)
                
                Text("• すべてのデータは匿名化されます\n• 個人を特定できる情報は収集されません\n• 第三者への提供は行いません\n• データは統計目的のみに使用されます")
                
                Text("データの保存")
                    .font(.headline)
                    .padding(.top)
                
                Text("録音データはお客様のデバイス内にのみ保存され、外部サーバーには送信されません。")
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StaticPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Premium機能")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Premium機能は今後実装予定です")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
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

struct RecordingDataManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: AudioSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var audioSessions: FetchedResults<AudioSession>
    
    @State private var showingDeleteAllAlert = false
    @State private var showingCacheAlert = false
    
    private var totalDataSize: String {
        let totalBytes: Int64 = audioSessions.reduce(0) { total, session in
            if let filePath = session.filePath,
               let fileSize = try? FileManager.default.attributesOfItem(atPath: filePath)[.size] as? Int64 {
                return total + fileSize
            }
            return total
        }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    private var oldestSessionDate: String {
        if let oldest = audioSessions.last?.createdAt {
            return oldest.formatted(date: .abbreviated, time: .omitted)
        }
        return "なし"
    }
    
    var body: some View {
        List {
            // 統計情報
            Section("データ統計") {
                HStack {
                    Text("総録音数")
                    Spacer()
                    Text("\(audioSessions.count)件")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("使用容量")
                    Spacer()
                    Text(totalDataSize)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("最古の録音")
                    Spacer()
                    Text(oldestSessionDate)
                        .foregroundColor(.secondary)
                }
            }
            
            // データ管理アクション
            Section("データ管理") {
                Button("キャッシュをクリア") {
                    showingCacheAlert = true
                }
                .foregroundColor(.orange)
                
                Button("全ての録音データを削除") {
                    showingDeleteAllAlert = true
                }
                .foregroundColor(.red)
            }
            
            // 説明
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("録音データについて")
                        .font(.headline)
                    
                    Text("• 録音ファイルはデバイス内にのみ保存されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• 外部サーバーには送信されません")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• アプリ削除時にすべてのデータが消去されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("録音データ管理")
        .navigationBarTitleDisplayMode(.inline)
        .alert("キャッシュクリア", isPresented: $showingCacheAlert) {
            Button("クリア", role: .destructive) {
                clearCache()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("一時ファイルをクリアします。録音データは保持されます。")
        }
        .alert("全データ削除", isPresented: $showingDeleteAllAlert) {
            Button("削除", role: .destructive) {
                deleteAllData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("すべての録音データが完全に削除されます。この操作は取り消せません。")
        }
    }
    
    private func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        try? FileManager.default.removeItem(at: cacheURL)
    }
    
    private func deleteAllData() {
        withAnimation {
            for session in audioSessions {
                // ファイルも削除
                if let filePath = session.filePath {
                    try? FileManager.default.removeItem(atPath: filePath)
                }
                viewContext.delete(session)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("削除エラー: \(error)")
            }
        }
    }
}