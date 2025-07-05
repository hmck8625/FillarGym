import Foundation
import Combine

class OpenAIService: ObservableObject {
    private var apiKey: String {
        // 1. Keychainから取得を試みる
        if let savedKey = try? KeychainManager.shared.retrieve(for: .openAIAPIKey), !savedKey.isEmpty {
            return savedKey
        }
        
        // 2. 環境変数から取得
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            // 環境変数にあればKeychainに保存
            try? KeychainManager.shared.save(envKey, for: .openAIAPIKey)
            return envKey
        }
        
        // 3. Info.plistから取得
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !plistKey.isEmpty {
            // Info.plistにあればKeychainに保存
            try? KeychainManager.shared.save(plistKey, for: .openAIAPIKey)
            return plistKey
        }
        
        // 4. ハードコードされたAPIキー（開発用）
        // 注意: 本番環境では使用しないでください
        let hardcodedKey = "sk-placeholder-key-for-development"
        if !hardcodedKey.isEmpty && hardcodedKey != "sk-placeholder-key-for-development" {
            try? KeychainManager.shared.save(hardcodedKey, for: .openAIAPIKey)
            return hardcodedKey
        }
        
        return ""
    }
    
    private let baseURL = "https://api.openai.com/v1"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    init() {
        let currentApiKey = apiKey
        if currentApiKey.isEmpty {
            print("⚠️ WARNING: OPENAI_API_KEY not found in Keychain or environment variables")
            print("📝 Debug: Checking all possible sources...")
            
            // Keychain確認
            if let keychainKey = try? KeychainManager.shared.retrieve(for: .openAIAPIKey) {
                print("🔑 Keychain contains key: \(String(keychainKey.prefix(10)))...")
            } else {
                print("🔑 Keychain: No key found")
            }
            
            // 環境変数確認
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
                print("🌍 Environment variable found: \(String(envKey.prefix(10)))...")
            } else {
                print("🌍 Environment variable: Not found")
            }
            
            // Info.plist確認
            if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
                print("📄 Info.plist found: \(String(plistKey.prefix(10)))...")
            } else {
                print("📄 Info.plist: Not found")
            }
        } else {
            print("✅ OpenAI API Key loaded successfully: \(String(currentApiKey.prefix(10)))...")
        }
    }
    
    // MARK: - Whisper API (音声→テキスト変換)
    func transcribeAudio(audioURL: URL) -> AnyPublisher<TranscriptionResponse, Error> {
        isProcessing = true
        print("Starting transcription for: \(audioURL.lastPathComponent)")
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(APIError.unknown))
                return
            }
            
            guard !self.apiKey.isEmpty else {
                print("Error: API key is empty")
                promise(.failure(APIError.missingAPIKey))
                return
            }
            
            var request = URLRequest(url: URL(string: "\(self.baseURL)/audio/transcriptions")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            do {
                let audioData = try Data(contentsOf: audioURL)
                let httpBody = self.createMultipartBody(
                    boundary: boundary,
                    audioData: audioData,
                    filename: audioURL.lastPathComponent
                )
                request.httpBody = httpBody
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        
                        if let error = error {
                            print("Transcription error: \(error)")
                            promise(.failure(error))
                            return
                        }
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            print("Transcription response status: \(httpResponse.statusCode)")
                        }
                        
                        guard let data = data else {
                            promise(.failure(APIError.noData))
                            return
                        }
                        
                        // デバッグ用：レスポンスを出力
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Transcription response: \(responseString)")
                        }
                        
                        do {
                            let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                            print("Transcription successful: \(transcription.text)")
                            promise(.success(transcription))
                        } catch {
                            print("Transcription decode error: \(error)")
                            promise(.failure(error))
                        }
                    }
                }.resume()
                
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Local Pre-processing
    private func performLocalPreProcessing(text: String, fillerWords: [String]) -> [(word: String, positions: [Int], contexts: [String])] {
        var results: [(word: String, positions: [Int], contexts: [String])] = []
        
        for filler in fillerWords {
            var positions: [Int] = []
            var contexts: [String] = []
            
            // 単語境界を考慮した正規表現パターン
            let pattern = "(?<![ぁ-んァ-ヶー一-龥a-zA-Z0-9])\(NSRegularExpression.escapedPattern(for: filler))(?![ぁ-んァ-ヶー一-龥a-zA-Z0-9])"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    let position = match.range.location
                    positions.append(position)
                    
                    // 前後の文脈を取得（前後10文字）
                    let contextStart = max(0, position - 10)
                    let contextEnd = min(nsString.length, position + filler.count + 10)
                    let contextRange = NSRange(location: contextStart, length: contextEnd - contextStart)
                    let context = nsString.substring(with: contextRange)
                    contexts.append(context)
                }
                
                if !positions.isEmpty {
                    results.append((word: filler, positions: positions, contexts: contexts))
                }
            } catch {
                print("正規表現エラー: \(error)")
            }
        }
        
        return results
    }
    
    // MARK: - Chunk Processing
    private func splitIntoChunks(text: String, chunkDurationMinutes: Int = 5) -> [(text: String, startTime: Double)] {
        // 日本語の平均発話速度: 350文字/分として計算
        let charsPerMinute = 350
        let chunkSize = charsPerMinute * chunkDurationMinutes
        
        var chunks: [(text: String, startTime: Double)] = []
        var currentPosition = 0
        var chunkIndex = 0
        
        while currentPosition < text.count {
            let endPosition = min(currentPosition + chunkSize, text.count)
            let startIndex = text.index(text.startIndex, offsetBy: currentPosition)
            let endIndex = text.index(text.startIndex, offsetBy: endPosition)
            
            // 文の途中で切れないように調整
            var adjustedEndIndex = endIndex
            if endPosition < text.count {
                // 句読点を探す
                let searchRange = startIndex..<endIndex
                if let lastPunctuation = text.range(of: "[。！？、.!?,]", options: .regularExpression, range: searchRange, locale: nil) {
                    adjustedEndIndex = text.index(after: lastPunctuation.lowerBound)
                }
            }
            
            let chunkText = String(text[startIndex..<adjustedEndIndex])
            let startTime = Double(chunkIndex * chunkDurationMinutes * 60) // 秒単位
            
            chunks.append((text: chunkText, startTime: startTime))
            
            currentPosition = text.distance(from: text.startIndex, to: adjustedEndIndex)
            chunkIndex += 1
        }
        
        return chunks
    }
    
    // MARK: - GPT API (フィラー語分析)
    func analyzeFillerWords(transcription: String, language: String = "ja", userSettings: UserSettings? = nil) -> AnyPublisher<FillerAnalysisResponse, Error> {
        // 5分以上の長さの場合はチャンク処理を使用
        let estimatedMinutes = Double(transcription.count) / 350.0
        
        print("📊 フィラー語分析開始:")
        print("- テキスト長: \(transcription.count)文字")
        print("- 推定時間: \(String(format: "%.1f", estimatedMinutes))分")
        
        // ローカル前処理（デバッグ用）
        var fillerWords = language == "ja" 
            ? ["えー", "あー", "その", "あの", "えっと", "まあ", "なんか", "ちょっと", "やっぱり"]
            : ["um", "uh", "like", "you know", "actually", "basically", "literally"]
        
        if let customWords = userSettings?.customFillerWordsArray, !customWords.isEmpty {
            fillerWords.append(contentsOf: customWords)
        }
        
        let localResults = performLocalPreProcessing(text: transcription, fillerWords: fillerWords)
        print("- ローカル検出: \(localResults.map { "\($0.word): \($0.positions.count)個" }.joined(separator: ", "))")
        
        if estimatedMinutes > 5 {
            print("- 処理方法: チャンク分割（5分単位）")
            return analyzeFillerWordsInChunks(transcription: transcription, language: language, userSettings: userSettings)
        } else {
            print("- 処理方法: 単一処理")
            return analyzeFillerWordsSingle(transcription: transcription, language: language, userSettings: userSettings)
        }
    }
    
    // チャンク分割して分析
    private func analyzeFillerWordsInChunks(transcription: String, language: String = "ja", userSettings: UserSettings? = nil) -> AnyPublisher<FillerAnalysisResponse, Error> {
        let chunks = splitIntoChunks(text: transcription, chunkDurationMinutes: 5)
        
        print("📦 チャンク分割完了:")
        print("- チャンク数: \(chunks.count)")
        for (index, chunk) in chunks.enumerated() {
            print("  - チャンク\(index + 1): \(chunk.text.count)文字（開始: \(String(format: "%.1f", chunk.startTime))秒）")
        }
        
        // 各チャンクを並列で分析
        let publishers = chunks.map { chunk in
            analyzeFillerWordsSingle(transcription: chunk.text, language: language, userSettings: userSettings)
                .map { response in
                    (response: response, startTime: chunk.startTime)
                }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { results in
                // 結果を統合
                self.mergeChunkResults(results, originalText: transcription)
            }
            .eraseToAnyPublisher()
    }
    
    // 結果の統合
    private func mergeChunkResults(_ results: [(response: FillerAnalysisResponse, startTime: Double)], originalText: String) -> FillerAnalysisResponse {
        var totalFillerCount = 0
        var allFillerWords: [String: (count: Int, positions: [Int], confidence: Double, contexts: [String])] = [:]
        var allSuggestions: Set<String> = []
        
        // 各チャンクの結果を統合
        for (response, startTimeOffset) in results {
            totalFillerCount += response.total_filler_count
            
            for fillerWord in response.filler_words {
                let word = fillerWord.word
                
                // 位置情報をグローバル位置に調整
                let adjustedPositions = fillerWord.positions.map { pos in
                    // チャンクの開始位置を考慮して調整
                    pos + Int(startTimeOffset * 350 / 60) // 概算位置
                }
                
                if var existing = allFillerWords[word] {
                    existing.count += fillerWord.count
                    existing.positions.append(contentsOf: adjustedPositions)
                    existing.confidence = max(existing.confidence, fillerWord.confidence)
                    existing.contexts.append(contentsOf: fillerWord.contexts ?? [])
                    allFillerWords[word] = existing
                } else {
                    allFillerWords[word] = (
                        count: fillerWord.count,
                        positions: adjustedPositions,
                        confidence: fillerWord.confidence,
                        contexts: fillerWord.contexts ?? []
                    )
                }
            }
            
            allSuggestions.formUnion(response.improvement_suggestions)
        }
        
        // 統合結果を作成
        let fillerWords = allFillerWords.map { key, value in
            DetectedFillerWord(
                word: key,
                count: value.count,
                positions: value.positions,
                confidence: value.confidence,
                contexts: Array(value.contexts.prefix(3)) // 最大3つの文脈例
            )
        }.sorted { $0.count > $1.count }
        
        // 全体の統計を再計算
        let estimatedDurationMinutes = Double(originalText.count) / 350.0
        let fillerRatePerMinute = estimatedDurationMinutes > 0 ? Double(totalFillerCount) / estimatedDurationMinutes : 0
        let speakingSpeed = estimatedDurationMinutes > 0 ? Double(originalText.count) / estimatedDurationMinutes : 350
        
        return FillerAnalysisResponse(
            total_filler_count: totalFillerCount,
            filler_rate_per_minute: fillerRatePerMinute,
            speaking_speed: speakingSpeed,
            filler_words: fillerWords,
            improvement_suggestions: Array(allSuggestions.prefix(5)).sorted() // 最大5つの提案
        )
    }
    
    // 単一テキストの分析（既存のメソッドをリネーム）
    private func analyzeFillerWordsSingle(transcription: String, language: String = "ja", userSettings: UserSettings? = nil) -> AnyPublisher<FillerAnalysisResponse, Error> {
        isProcessing = true
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(APIError.unknown))
                return
            }
            
            guard !self.apiKey.isEmpty else {
                promise(.failure(APIError.missingAPIKey))
                return
            }
            
            let systemPrompt = self.createFillerAnalysisPrompt(language: language, userSettings: userSettings)
            let requestBody = ChatCompletionRequest(
                model: "gpt-4o-mini",
                messages: [
                    ChatMessage(role: "system", content: systemPrompt),
                    ChatMessage(role: "user", content: transcription)
                ],
                temperature: 0.3,
                response_format: ResponseFormat(type: "json_object")
            )
            
            var request = URLRequest(url: URL(string: "\(self.baseURL)/chat/completions")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONEncoder().encode(requestBody)
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        
                        if let error = error {
                            promise(.failure(error))
                            return
                        }
                        
                        guard let data = data else {
                            promise(.failure(APIError.noData))
                            return
                        }
                        
                        do {
                            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                            guard let content = chatResponse.choices.first?.message.content else {
                                promise(.failure(APIError.invalidResponse))
                                return
                            }
                            
                            let analysisResponse = try JSONDecoder().decode(FillerAnalysisResponse.self, from: content.data(using: .utf8)!)
                            promise(.success(analysisResponse))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }.resume()
                
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    private func createMultipartBody(boundary: String, audioData: Data, filename: String) -> Data {
        var body = Data()
        
        // Model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Language parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("ja\r\n".data(using: .utf8)!)
        
        // Audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func createFillerAnalysisPrompt(language: String, userSettings: UserSettings?) -> String {
        // デフォルトのフィラー語
        var fillerWords = language == "ja" 
            ? ["えー", "あー", "その", "あの", "えっと", "まあ", "なんか", "ちょっと", "やっぱり"]
            : ["um", "uh", "like", "you know", "actually", "basically", "literally"]
        
        // カスタムフィラー語を追加
        if let customWords = userSettings?.customFillerWordsArray, !customWords.isEmpty {
            fillerWords.append(contentsOf: customWords)
        }
        
        // 重複を除去
        fillerWords = Array(Set(fillerWords))
        
        return """
        あなたは音声分析の専門家です。与えられたテキストからフィラー語を高精度で検出・分析してください。

        ## 検出ルール（重要）
        1. **単語境界の厳守**: 独立した単語として出現している場合のみ検出してください
           - ✅ 検出する例: 「その話は」の「その」、「えー、今日は」の「えー」
           - ❌ 検出しない例: 「そのため」「あのう」「まあまあ」の一部
        
        2. **文脈を考慮**: 以下の場合は検出から除外
           - 意味のある指示語として使われている場合（「その本」「あの人」など）
           - 複合語の一部（「そのため」「その他」「ちょっとした」など）
        
        3. **位置による判定**:
           - 文頭の「えー」「あー」は高確率でフィラー語
           - 文中の「なんか」「ちょっと」は前後の文脈を確認
           - 同じ語が短時間に繰り返される場合は高確率でフィラー語

        ## 検出対象のフィラー語
        \(fillerWords.joined(separator: ", "))

        ## 分析手順
        1. テキストを句読点で区切って分析
        2. 各フィラー語を正規表現的に検出（単語境界を考慮）
        3. 前後の文脈（前後5単語）を確認
        4. 信頼度スコア（0.0-1.0）を算出

        ## JSON出力形式
        {
          "total_filler_count": 総フィラー語数（信頼度0.7以上のみカウント）,
          "filler_rate_per_minute": 1分あたりのフィラー語数,
          "speaking_speed": 発話速度（語数/分）,
          "filler_words": [
            {
              "word": "フィラー語",
              "count": 出現回数,
              "positions": [出現位置の文字インデックス],
              "confidence": 信頼度(0-1),
              "contexts": ["前後の文脈例1", "前後の文脈例2"]
            }
          ],
          "improvement_suggestions": [
            "具体的な改善提案1",
            "具体的な改善提案2", 
            "具体的な改善提案3"
          ]
        }

        ## 信頼度の基準
        - 1.0: 明確なフィラー語（文頭の「えー」など）
        - 0.8-0.9: 高確率でフィラー語（繰り返しパターン）
        - 0.7-0.8: フィラー語の可能性が高い
        - 0.7未満: 除外（意味のある使用の可能性）

        テキストの長さから推定発話時間を計算し、適切な分析を行ってください。
        日本語の場合、平均的な発話速度は300-400文字/分として計算してください。
        """
    }
}

// MARK: - API Models
struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let response_format: ResponseFormat?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case response_format = "response_format"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ResponseFormat: Codable {
    let type: String
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: ChatMessage
    }
}

struct FillerAnalysisResponse: Codable {
    let total_filler_count: Int
    let filler_rate_per_minute: Double
    let speaking_speed: Double
    let filler_words: [DetectedFillerWord]
    let improvement_suggestions: [String]
    
    enum CodingKeys: String, CodingKey {
        case total_filler_count = "total_filler_count"
        case filler_rate_per_minute = "filler_rate_per_minute"
        case speaking_speed = "speaking_speed"
        case filler_words = "filler_words"
        case improvement_suggestions = "improvement_suggestions"
    }
}

struct DetectedFillerWord: Codable {
    let word: String
    let count: Int
    let positions: [Int]  // Double から Int に変更（文字インデックス）
    let confidence: Double
    let contexts: [String]?  // 文脈例（オプショナル）
}

enum APIError: Error, LocalizedError {
    case missingAPIKey
    case noData
    case invalidResponse
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "APIキーが設定されていません"
        case .noData:
            return "データが取得できませんでした"
        case .invalidResponse:
            return "不正なレスポンスです"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}