import SwiftUI

struct APIKeySettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isValidating = false
    @State private var keyIsValid = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("OpenAI API キー") {
                    VStack(alignment: .leading, spacing: 10) {
                        SecureField("APIキーを入力", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("OpenAI APIキーは[OpenAI Platform](https://platform.openai.com/api-keys)から取得できます")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if keyIsValid {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("有効なAPIキーです")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
                
                Section("使用量の目安") {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Whisper API: $0.006/分")
                        Text("• GPT-4 API: ~$0.01/分析")
                        Text("• 月100回の分析で約$1-2程度")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Section {
                    Button(action: validateAndSaveKey) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "key.fill")
                            }
                            Text(isValidating ? "検証中..." : "保存して検証")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    
                    if KeychainManager.shared.exists(for: .openAIAPIKey) {
                        Button(action: deleteKey) {
                            HStack {
                                Image(systemName: "trash")
                                Text("保存済みキーを削除")
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("API設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("通知", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadExistingKey()
        }
    }
    
    private func loadExistingKey() {
        if let savedKey = try? KeychainManager.shared.retrieve(for: .openAIAPIKey) {
            apiKey = savedKey
            keyIsValid = true
        }
    }
    
    private func validateAndSaveKey() {
        isValidating = true
        
        // 簡単な形式チェック
        guard apiKey.hasPrefix("sk-") && apiKey.count > 20 else {
            showAlert("無効なAPIキー形式です。OpenAIのAPIキーは'sk-'で始まります。")
            isValidating = false
            return
        }
        
        // APIキーを検証（簡単なテストリクエスト）
        testAPIKey { isValid in
            if isValid {
                do {
                    try KeychainManager.shared.save(apiKey, for: .openAIAPIKey)
                    keyIsValid = true
                    showAlert("APIキーを保存しました")
                } catch {
                    showAlert("保存エラー: \(error.localizedDescription)")
                }
            } else {
                showAlert("APIキーが無効です。正しいキーを入力してください。")
            }
            isValidating = false
        }
    }
    
    private func testAPIKey(completion: @escaping (Bool) -> Void) {
        // 簡単なAPI検証リクエスト
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    completion(httpResponse.statusCode == 200)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    private func deleteKey() {
        do {
            try KeychainManager.shared.delete(for: .openAIAPIKey)
            apiKey = ""
            keyIsValid = false
            showAlert("APIキーを削除しました")
        } catch {
            showAlert("削除エラー: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}