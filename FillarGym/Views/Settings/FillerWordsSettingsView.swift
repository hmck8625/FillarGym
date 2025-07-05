import SwiftUI
import CoreData

struct FillerWordsSettingsView: View {
    let settings: UserSettings
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLanguage: String
    @State private var customFillerWords: [String]
    @State private var newFillerWord = ""
    @State private var showingAddAlert = false
    
    private let defaultFillerWords: [String]
    
    init(settings: UserSettings) {
        self.settings = settings
        _selectedLanguage = State(initialValue: settings.language ?? "ja")
        _customFillerWords = State(initialValue: settings.customFillerWordsArray)
        self.defaultFillerWords = UserSettings.defaultFillerWords(for: settings.language ?? "ja")
    }
    
    var allFillerWords: [String] {
        let defaults = UserSettings.defaultFillerWords(for: selectedLanguage)
        return defaults + customFillerWords
    }
    
    var body: some View {
        List {
            // 言語設定
            Section("言語設定") {
                Picker("検出言語", selection: $selectedLanguage) {
                    Text("日本語").tag("ja")
                    Text("English").tag("en")
                }
                .onChange(of: selectedLanguage) { _, newLanguage in
                    settings.language = newLanguage
                    saveSettings()
                }
            }
            
            // デフォルトフィラー語
            Section("デフォルトフィラー語") {
                ForEach(UserSettings.defaultFillerWords(for: selectedLanguage), id: \.self) { word in
                    HStack {
                        Text(word)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            
            // カスタムフィラー語
            Section(header: 
                HStack {
                    Text("カスタムフィラー語")
                    Spacer()
                    Button(action: {
                        showingAddAlert = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            ) {
                if customFillerWords.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.bubble")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("独自のフィラー語を追加")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("「だから」「つまり」「ちなみに」など")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(customFillerWords, id: \.self) { word in
                        HStack {
                            Text(word)
                                .font(.body)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    removeCustomWord(word)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                // クイック追加ボタン
                if !customFillerWords.isEmpty {
                    Button(action: {
                        showingAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            Text("新しいフィラー語を追加")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // 検出設定
            Section("検出設定") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("検出感度")
                        .font(.headline)
                    
                    Picker("検出感度", selection: Binding(
                        get: { Int(settings.detectionSensitivity) },
                        set: { 
                            settings.detectionSensitivity = Int16($0)
                            saveSettings()
                        }
                    )) {
                        Text("低 - 明確なフィラー語のみ").tag(0)
                        Text("中 - バランス良く検出").tag(1)
                        Text("高 - 微細な言い淀みも検出").tag(2)
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text("検出感度が高いほど、より多くのフィラー語が検出されますが、誤検出も増える可能性があります。")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // プレビュー
            Section("検出対象フィラー語一覧") {
                Text("現在の設定で検出されるフィラー語:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(allFillerWords, id: \.self) { word in
                        Text(word)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .navigationTitle("フィラー語設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("新しいフィラー語を追加", isPresented: $showingAddAlert) {
            TextField("フィラー語を入力", text: $newFillerWord)
            Button("追加") {
                addCustomWord()
            }
            Button("キャンセル", role: .cancel) {
                newFillerWord = ""
            }
        } message: {
            Text("検出したいフィラー語を入力してください")
        }
    }
    
    private func addCustomWord() {
        let trimmed = newFillerWord.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !customFillerWords.contains(trimmed) {
            customFillerWords.append(trimmed)
            settings.customFillerWordsArray = customFillerWords
            saveSettings()
        }
        newFillerWord = ""
    }
    
    private func removeCustomWord(_ word: String) {
        customFillerWords.removeAll { $0 == word }
        settings.customFillerWordsArray = customFillerWords
        saveSettings()
    }
    
    private func saveSettings() {
        settings.updatedAt = Date()
        do {
            try viewContext.save()
        } catch {
            print("設定保存エラー: \(error)")
        }
    }
}