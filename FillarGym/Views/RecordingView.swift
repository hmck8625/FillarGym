import SwiftUI
import CoreData

struct RecordingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioRecorder = AudioRecorderManager()
    @State private var sessionTitle = ""
    @State private var showingPermissionAlert = false
    @State private var showingAnalysisView = false
    @State private var completedSession: AudioSession?
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var fileInfo: AudioFileInfo?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // タイトル入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("録音タイトル")
                        .font(.headline)
                    TextField("録音セッション名を入力（任意）", text: $sessionTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 録音状態表示
                VStack(spacing: 20) {
                    // 音声レベルビジュアライザー
                    AudioLevelVisualizer(level: audioRecorder.audioLevels, isRecording: audioRecorder.isRecording)
                    
                    // 時間表示
                    VStack(spacing: 8) {
                        Text(audioRecorder.formatTime(audioRecorder.recordingDuration))
                            .font(.system(size: 48, weight: .thin, design: .monospaced))
                            .foregroundColor(audioRecorder.isRecording ? .red : .primary)
                        
                        if audioRecorder.isRecording {
                            Text("残り \(audioRecorder.formatTime(audioRecorder.remainingTime))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 録音状態テキスト
                    Text(audioRecorder.isRecording ? "録音中..." : "録音を開始する準備ができました")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // コントロールボタン
                VStack(spacing: 20) {
                    // メイン録音ボタン
                    Button(action: {
                        if audioRecorder.hasPermission {
                            if audioRecorder.isRecording {
                                audioRecorder.stopRecording()
                                // メインスレッドで確実に実行
                                DispatchQueue.main.async {
                                    saveRecordingSession()
                                }
                            } else {
                                audioRecorder.startRecording()
                            }
                        } else {
                            showingPermissionAlert = true
                        }
                    }) {
                        Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                    }
                    .disabled(!audioRecorder.hasPermission)
                    
                    // キャンセルボタン（録音中のみ表示）
                    if audioRecorder.isRecording {
                        Button("キャンセル") {
                            audioRecorder.cancelRecording()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("録音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        if audioRecorder.isRecording {
                            audioRecorder.cancelRecording()
                        }
                        dismiss()
                    }
                    .disabled(audioRecorder.isRecording)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ファイル選択") {
                        showingFilePicker = true
                    }
                    .disabled(audioRecorder.isRecording)
                }
            }
        }
        .alert("マイクの許可が必要です", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("録音機能を使用するには、設定アプリでマイクの使用を許可してください。")
        }
        .alert("エラー", isPresented: .constant(audioRecorder.errorMessage != nil)) {
            Button("OK") {
                audioRecorder.errorMessage = nil
            }
        } message: {
            Text(audioRecorder.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showingAnalysisView) {
            if let session = completedSession {
                AnalysisProcessingView(audioSession: session)
                    .onAppear {
                        print("📊 AnalysisProcessingViewシート表示開始")
                    }
            } else {
                VStack {
                    Text("セッション情報が見つかりません")
                    Button("閉じる") {
                        showingAnalysisView = false
                    }
                }
                .onAppear {
                    print("❌ completedSessionがnil")
                }
            }
        }
        .onChange(of: showingAnalysisView) { isShowing in
            print("📊 showingAnalysisView変更: \(isShowing)")
            print("📊 completedSession: \(completedSession?.id?.uuidString ?? "nil")")
        }
        .onAppear {
            audioRecorder.checkPermissions()
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView(
                selectedURL: $selectedFileURL,
                allowedTypes: [.audio, .mpeg4Audio, .wav, .mp3],
                onPick: { url in
                    print("🎵 ファイル選択完了: \(url)")
                    print("- ファイル名: \(url.lastPathComponent)")
                    print("- パス: \(url.path)")
                    print("- 存在確認: \(FileManager.default.fileExists(atPath: url.path))")
                    validateAndProcessFile(url)
                },
                onCancel: {
                    print("❌ ファイル選択キャンセル")
                    showingFilePicker = false
                }
            )
        }
        .sheet(item: $fileInfo) { info in
            FileInfoView(
                fileInfo: info,
                onConfirm: {
                    print("📋 ファイル確認完了: 分析処理開始")
                    fileInfo = nil
                    processAudioFile(info)
                },
                onCancel: {
                    print("📋 ファイル確認キャンセル")
                    fileInfo = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                print("📋 FileInfoViewシート表示開始")
            }
        }
    }
    
    private func saveRecordingSession() {
        guard let recordingURL = audioRecorder.recordingURL else {
            audioRecorder.errorMessage = "録音ファイルが見つかりません"
            return
        }
        
        let session = AudioSession(context: viewContext, 
                                   title: sessionTitle.isEmpty ? "録音セッション" : sessionTitle,
                                   duration: audioRecorder.recordingDuration)
        session.filePath = recordingURL.path
        
        // 必須フィールドの確認（デバッグ用）
        print("AudioSession Debug Info:")
        print("- ID: \(session.id?.uuidString ?? "nil")")
        print("- Title: \(session.title ?? "nil")")
        print("- Duration: \(session.duration)")
        print("- FilePath: \(session.filePath ?? "nil")")
        print("- CreatedAt: \(session.createdAt?.description ?? "nil")")
        
        do {
            try viewContext.save()
            completedSession = session
            showingAnalysisView = true
        } catch {
            // Core Dataのvalidationエラーを詳しく調査
            let nsError = error as NSError
            var errorMessages: [String] = ["録音の保存に失敗しました"]
            
            // エラーコードと詳細を出力
            errorMessages.append("Error Code: \(nsError.code)")
            errorMessages.append("Error Domain: \(nsError.domain)")
            
            // validation errorsの詳細を取得
            if let validationErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                errorMessages.append("Validation Errors:")
                for (index, validationError) in validationErrors.enumerated() {
                    errorMessages.append("\(index + 1). \(validationError.localizedDescription)")
                    if let key = validationError.userInfo[NSValidationKeyErrorKey] as? String {
                        errorMessages.append("   Key: \(key)")
                    }
                    if let value = validationError.userInfo[NSValidationValueErrorKey] {
                        errorMessages.append("   Value: \(value)")
                    }
                }
            }
            
            // デバッグ用にコンソールに出力
            print("Core Data Save Error Details:")
            errorMessages.forEach { print($0) }
            
            audioRecorder.errorMessage = errorMessages.joined(separator: "\n")
        }
    }
    
    private func validateAndProcessFile(_ url: URL) {
        showingFilePicker = false
        
        print("🔍 ファイル検証開始...")
        
        Task {
            let result = await AudioFileValidator.shared.validateAudioFile(at: url)
            
            await MainActor.run {
                switch result {
                case .success(let info):
                    print("✅ ファイル検証成功 - FileInfoView表示準備")
                    print("- Info詳細: \(info.url.lastPathComponent), \(info.formattedDuration), \(info.formattedFileSize)")
                    
                    // fileInfoを設定（シートは自動で表示される）
                    self.fileInfo = info
                    print("📋 fileInfo設定完了: \(self.fileInfo?.id.uuidString ?? "nil")")
                    
                case .failure(let error):
                    print("❌ ファイル検証失敗: \(error)")
                    audioRecorder.errorMessage = error
                }
            }
        }
    }
    
    private func processAudioFile(_ info: AudioFileInfo) {
        
        print("📁 ファイル処理開始:")
        print("- 元ファイルURL: \(info.url)")
        print("- ファイルサイズ: \(info.formattedFileSize)")
        print("- 再生時間: \(info.formattedDuration)")
        
        // セキュリティスコープアクセス開始
        let accessSucceeded = info.url.startAccessingSecurityScopedResource()
        print("- セキュリティスコープアクセス: \(accessSucceeded ? "成功" : "失敗")")
        
        defer {
            if accessSucceeded {
                info.url.stopAccessingSecurityScopedResource()
            }
        }
        
        // ドキュメントディレクトリにコピー
        guard let copiedURL = AudioFileValidator.shared.copyToDocuments(from: info.url) else {
            audioRecorder.errorMessage = "ファイルのコピーに失敗しました"
            return
        }
        
        print("- コピー先URL: \(copiedURL)")
        
        // AudioSessionを作成
        let fileName = info.url.deletingPathExtension().lastPathComponent
        let session = AudioSession(context: viewContext,
                                   title: sessionTitle.isEmpty ? fileName : sessionTitle,
                                   duration: info.duration)
        session.filePath = copiedURL.path
        
        // 必須フィールドの確認
        print("AudioSession作成:")
        print("- ID: \(session.id?.uuidString ?? "nil")")
        print("- Title: \(session.title ?? "nil")")
        print("- Duration: \(session.duration)")
        print("- FilePath: \(session.filePath ?? "nil")")
        print("- CreatedAt: \(session.createdAt?.description ?? "nil")")
        
        do {
            try viewContext.save()
            print("✅ AudioSession保存成功")
            
            // メインスレッドで確実に状態を更新
            DispatchQueue.main.async {
                print("📊 状態更新開始")
                self.completedSession = session
                print("📊 completedSession設定: \(session.id?.uuidString ?? "nil")")
                self.showingAnalysisView = true
                print("📊 showingAnalysisView設定: \(self.showingAnalysisView)")
                print("📊 分析画面表示開始")
            }
            
        } catch {
            let nsError = error as NSError
            print("❌ AudioSession保存エラー:")
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
                }
            }
            
            audioRecorder.errorMessage = "ファイル情報の保存に失敗しました: \(error.localizedDescription)"
        }
    }
}

struct AudioLevelVisualizer: View {
    let level: Float
    let isRecording: Bool
    
    var body: some View {
        ZStack {
            // 背景円
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 200, height: 200)
            
            // レベル表示円
            Circle()
                .trim(from: 0, to: CGFloat(level))
                .stroke(
                    isRecording ? Color.red : Color.blue,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.1), value: level)
            
            // 中央アイコン
            Image(systemName: isRecording ? "waveform" : "mic")
                .font(.system(size: 40))
                .foregroundColor(isRecording ? .red : .blue)
        }
    }
}

// 分析処理画面
struct AnalysisProcessingView: View {
    let audioSession: AudioSession
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var analysisManager = AnalysisManager()
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // プログレスインジケーター
                VStack(spacing: 20) {
                    ProgressView(value: analysisManager.analysisProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2)
                    
                    Text(analysisManager.currentStep)
                        .font(.headline)
                    
                    Text("しばらくお待ちください...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                
                Spacer()
                
                if analysisManager.isAnalyzing {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                } else {
                    Button("結果を見る") {
                        showingResults = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("分析中")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("📊 AnalysisProcessingView表示完了")
            print("- AudioSession ID: \(audioSession.id?.uuidString ?? "nil")")
            print("- APIキー存在確認: \(KeychainManager.shared.exists(for: .openAIAPIKey))")
            
            // APIキーが設定されている場合は実際の分析、なければモック分析
            if KeychainManager.shared.exists(for: .openAIAPIKey) {
                print("🔑 実際の分析処理開始")
                analysisManager.analyzeAudioSession(audioSession, context: viewContext)
            } else {
                print("🎭 モック分析処理開始")
                analysisManager.performMockAnalysis(for: audioSession, context: viewContext)
            }
        }
        .alert("エラー", isPresented: .constant(analysisManager.errorMessage != nil)) {
            Button("OK") {
                analysisManager.errorMessage = nil
                dismiss()
            }
        } message: {
            Text(analysisManager.errorMessage ?? "")
        }
        .onChange(of: analysisManager.isAnalyzing) {
            if !analysisManager.isAnalyzing && analysisManager.errorMessage == nil {
                // 分析完了後、少し待ってから自動で結果画面に遷移
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingResults = true
                }
            }
        }
        .sheet(isPresented: $showingResults) {
            if let analysis = audioSession.analysis {
                AnalysisResultView(analysis: analysis, onComplete: {
                    // 結果画面を閉じる
                    showingResults = false
                    // 分析処理画面も閉じる
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                })
            }
        }
    }
}