import Foundation
import CoreData
import Combine

class AnalysisManager: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentStep = ""
    @Published var errorMessage: String?
    
    private let openAIService = OpenAIService()
    private var cancellables = Set<AnyCancellable>()
    
    private let analysisSteps = [
        "音声を準備中...",
        "音声をアップロード中...",
        "文字起こし中...",
        "フィラー語を検出中...",
        "分析結果を保存中..."
    ]
    
    func analyzeAudioSession(_ audioSession: AudioSession, context: NSManagedObjectContext) {
        print("🎯 AnalysisManager.analyzeAudioSession開始")
        print("- AudioSession ID: \(audioSession.id?.uuidString ?? "nil")")
        print("- FilePath: \(audioSession.filePath ?? "nil")")
        
        guard let filePath = audioSession.filePath else {
            print("❌ 音声ファイルパスが見つかりません")
            errorMessage = "音声ファイルが見つかりません"
            return
        }
        
        // ファイルパスからURLを作成（file://形式の場合とパスのみの場合に対応）
        let audioURL: URL
        if filePath.hasPrefix("file://") {
            audioURL = URL(string: filePath)!
        } else {
            audioURL = URL(fileURLWithPath: filePath)
        }
        
        print("🚀 分析処理状態初期化")
        isAnalyzing = true
        analysisProgress = 0.0
        updateStep(0)
        print("- isAnalyzing: \(isAnalyzing)")
        print("- analysisProgress: \(analysisProgress)")
        print("- currentStep: \(currentStep)")
        
        // Step 1: 音声ファイルの準備
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateStep(1)
            
            // Step 2: Whisper APIで文字起こし
            self.openAIService.transcribeAudio(audioURL: audioURL)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.handleError(error)
                        }
                    },
                    receiveValue: { [weak self] transcription in
                        self?.updateStep(2)
                        self?.analyzeTranscription(transcription.text, for: audioSession, context: context)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    private func analyzeTranscription(_ text: String, for audioSession: AudioSession, context: NSManagedObjectContext) {
        updateStep(3)
        
        // 文字起こし結果を保存
        audioSession.transcription = text
        print("Transcription saved: \(text)")
        
        // ユーザー設定を取得
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        let userSettings = try? context.fetch(request).first
        let language = userSettings?.language ?? "ja"
        
        // GPT APIでフィラー語分析
        openAIService.analyzeFillerWords(transcription: text, language: language, userSettings: userSettings)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Analysis failed: \(error)")
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] analysisResponse in
                    print("Analysis completed: \(analysisResponse.total_filler_count) fillers detected")
                    self?.updateStep(4)
                    self?.saveAnalysisResults(analysisResponse, for: audioSession, context: context)
                }
            )
            .store(in: &cancellables)
    }
    
    private func saveAnalysisResults(_ response: FillerAnalysisResponse, for audioSession: AudioSession, context: NSManagedObjectContext) {
        print("💾 分析結果保存開始:")
        print("- AudioSession ID: \(audioSession.id?.uuidString ?? "nil")")
        print("- AudioSession isDeleted: \(audioSession.isDeleted)")
        print("- AudioSession managedObjectContext: \(audioSession.managedObjectContext != nil)")
        print("- フィラー語数: \(response.total_filler_count)")
        
        // AudioSessionが有効かチェック
        guard !audioSession.isDeleted, audioSession.managedObjectContext != nil else {
            print("❌ AudioSessionが無効です")
            handleError(NSError(domain: "AnalysisManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "AudioSessionが無効です"]))
            return
        }
        
        // 既存の分析があるかチェックして削除
        if let existingAnalysis = audioSession.analysis {
            print("⚠️ 既存の分析を削除: \(existingAnalysis.id?.uuidString ?? "nil")")
            context.delete(existingAnalysis)
        }
        
        // FillerAnalysisエンティティを作成
        let analysis = FillerAnalysis(context: context, audioSession: audioSession)
        analysis.fillerCount = Int16(response.total_filler_count)
        analysis.fillerRate = response.filler_rate_per_minute
        analysis.speakingSpeed = response.speaking_speed
        
        // 関係性を明示的に設定
        analysis.audioSession = audioSession
        audioSession.analysis = analysis
        
        // 関係の確認
        print("- Analysis ID: \(analysis.id?.uuidString ?? "nil")")
        print("- Analysis AudioSession: \(analysis.audioSession?.id?.uuidString ?? "nil")")
        print("- Analysis Date: \(analysis.analysisDate?.description ?? "nil")")
        
        // 検出されたフィラー語を保存
        for (index, fillerWord) in response.filler_words.enumerated() {
            let fillerEntity = FillerWord(context: context)
            fillerEntity.id = UUID()
            fillerEntity.word = fillerWord.word
            fillerEntity.count = Int16(fillerWord.count)
            fillerEntity.confidence = fillerWord.confidence
            fillerEntity.timestamp = fillerWord.positions.first.map { Double($0) } ?? 0.0
            fillerEntity.analysis = analysis
            
            print("  - フィラー語[\(index)]: \(fillerWord.word) (\(fillerWord.count)回)")
        }
        
        // バリデーション前の最終確認
        print("保存前の検証:")
        print("- Analysis has audioSession: \(analysis.audioSession != nil)")
        print("- AudioSession has valid ID: \(analysis.audioSession?.id != nil)")
        
        // Core Dataに保存
        do {
            try context.save()
            print("✅ 分析結果保存成功")
            completeAnalysis()
        } catch {
            let nsError = error as NSError
            print("❌ 分析結果保存エラー:")
            print("- Error Code: \(nsError.code)")
            print("- Error Domain: \(nsError.domain)")
            print("- Description: \(nsError.localizedDescription)")
            
            // 詳細なバリデーションエラーの表示
            if let validationErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for (index, validationError) in validationErrors.enumerated() {
                    print("  \(index + 1). \(validationError.localizedDescription)")
                    if let key = validationError.userInfo[NSValidationKeyErrorKey] as? String {
                        print("     Key: \(key)")
                    }
                    if let value = validationError.userInfo[NSValidationValueErrorKey] {
                        print("     Value: \(value)")
                    }
                }
            }
            
            handleError(error)
        }
    }
    
    private func updateStep(_ stepIndex: Int) {
        if stepIndex < analysisSteps.count {
            currentStep = analysisSteps[stepIndex]
            analysisProgress = Double(stepIndex) / Double(analysisSteps.count)
        }
    }
    
    private func completeAnalysis() {
        analysisProgress = 1.0
        currentStep = "分析完了"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAnalyzing = false
            self.analysisProgress = 0.0
            self.currentStep = ""
        }
    }
    
    private func handleError(_ error: Error) {
        isAnalyzing = false
        analysisProgress = 0.0
        currentStep = ""
        errorMessage = error.localizedDescription
    }
    
    // MARK: - Mock Analysis (開発・テスト用)
    func performMockAnalysis(for audioSession: AudioSession, context: NSManagedObjectContext) {
        isAnalyzing = true
        analysisProgress = 0.0
        
        let mockSteps = analysisSteps
        var currentStepIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if currentStepIndex < mockSteps.count {
                self.currentStep = mockSteps[currentStepIndex]
                self.analysisProgress = Double(currentStepIndex + 1) / Double(mockSteps.count)
                currentStepIndex += 1
            } else {
                timer.invalidate()
                self.createMockAnalysisResults(for: audioSession, context: context)
            }
        }
    }
    
    private func createMockAnalysisResults(for audioSession: AudioSession, context: NSManagedObjectContext) {
        print("🎭 モック分析結果作成開始:")
        print("- AudioSession ID: \(audioSession.id?.uuidString ?? "nil")")
        
        // 既存の分析があるかチェックして削除
        if let existingAnalysis = audioSession.analysis {
            print("⚠️ 既存のモック分析を削除: \(existingAnalysis.id?.uuidString ?? "nil")")
            context.delete(existingAnalysis)
        }
        
        // モック用の分析結果を作成
        let analysis = FillerAnalysis(context: context, audioSession: audioSession)
        analysis.fillerCount = Int16.random(in: 3...15)
        analysis.fillerRate = Double.random(in: 2.0...8.0)
        analysis.speakingSpeed = Double.random(in: 120...180)
        
        // 関係性を明示的に設定
        analysis.audioSession = audioSession
        audioSession.analysis = analysis
        
        print("- モック分析作成完了: \(analysis.fillerCount)個のフィラー語")
        print("- Analysis AudioSession: \(analysis.audioSession?.id?.uuidString ?? "nil")")
        
        // ユーザー設定を取得
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        let userSettings = try? context.fetch(request).first
        let language = userSettings?.language ?? "ja"
        
        // モックのフィラー語データ（カスタムフィラー語も含む）
        var mockFillerWords = UserSettings.defaultFillerWords(for: language)
        if let customWords = userSettings?.customFillerWordsArray, !customWords.isEmpty {
            mockFillerWords.append(contentsOf: customWords)
        }
        
        // ランダムに選択
        let selectedWords = mockFillerWords.shuffled().prefix(Int.random(in: 2...4))
        
        for word in selectedWords {
            let fillerEntity = FillerWord(context: context)
            fillerEntity.id = UUID()
            fillerEntity.word = word
            fillerEntity.count = Int16.random(in: 1...5)
            fillerEntity.confidence = Double.random(in: 0.7...1.0)
            fillerEntity.timestamp = Double.random(in: 0...audioSession.duration)
            fillerEntity.analysis = analysis
        }
        
        // モックの文字起こし（カスタムフィラー語も含める）
        let fillerExamples = selectedWords.joined(separator: "、")
        audioSession.transcription = "こんにちは、\(fillerExamples)、今日はですね、プレゼンテーションをさせていただきます。よろしくお願いします。"
        
        do {
            try context.save()
            completeAnalysis()
        } catch {
            handleError(error)
        }
    }
}