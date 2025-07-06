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
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header Section
                        headerSection
                        
                        // Main Recording Interface
                        mainRecordingInterface
                        
                        // Control Buttons
                        controlButtonsSection
                        
                        // Secondary Actions
                        secondaryActionsSection
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .frame(minHeight: geometry.size.height)
                }
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
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        Image(systemName: "folder")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .disabled(audioRecorder.isRecording)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Text("録音タイトル")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !sessionTitle.isEmpty {
                        StatusBadge(text: "カスタム", status: .info)
                    }
                }
                
                TextField("録音セッション名を入力（任意）", text: $sessionTitle)
                    .font(DesignSystem.Typography.body)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(sessionTitle.isEmpty ? DesignSystem.Colors.border : DesignSystem.Colors.primary, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Main Recording Interface
    private var mainRecordingInterface: some View {
        ModernCard(elevation: .high, padding: DesignSystem.Spacing.xl) {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Status Indicator
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(audioRecorder.isRecording ? "録音中" : "録音準備完了")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    StatusBadge(
                        text: audioRecorder.isRecording ? "LIVE" : "READY",
                        status: audioRecorder.isRecording ? .error : .success
                    )
                }
                
                // Modern Audio Visualizer
                ModernAudioLevelVisualizer(
                    level: audioRecorder.audioLevels,
                    isRecording: audioRecorder.isRecording
                )
                
                // Time Display
                timeDisplaySection
                
                // Progress indicator for recording
                if audioRecorder.isRecording {
                    progressSection
                }
            }
        }
    }
    
    // MARK: - Time Display Section
    private var timeDisplaySection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text(audioRecorder.formatTime(audioRecorder.recordingDuration))
                .font(DesignSystem.Typography.numberLarge.monospaced())
                .foregroundColor(audioRecorder.isRecording ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
                .animation(DesignSystem.Animation.quick, value: audioRecorder.recordingDuration)
            
            if audioRecorder.isRecording {
                Text("残り \(audioRecorder.formatTime(audioRecorder.remainingTime))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ProgressView(value: audioRecorder.recordingProgress)
                .progressViewStyle(ModernProgressViewStyle(color: DesignSystem.Colors.error))
            
            HStack {
                Text("0:00")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Spacer()
                
                Text(audioRecorder.formatTime(audioRecorder.maxRecordingDuration))
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
    }
    
    // MARK: - Control Buttons Section
    private var controlButtonsSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Main Recording Button
            RecordingButton(
                isRecording: audioRecorder.isRecording,
                hasPermission: audioRecorder.hasPermission,
                onTap: {
                    if audioRecorder.hasPermission {
                        if audioRecorder.isRecording {
                            audioRecorder.stopRecording()
                            DispatchQueue.main.async {
                                saveRecordingSession()
                            }
                        } else {
                            audioRecorder.startRecording()
                        }
                    } else {
                        showingPermissionAlert = true
                    }
                }
            )
            
            // Cancel Button (only during recording)
            if audioRecorder.isRecording {
                PillButton(
                    title: "録音をキャンセル",
                    icon: "xmark",
                    size: .medium,
                    variant: .outline
                ) {
                    audioRecorder.cancelRecording()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Secondary Actions Section
    private var secondaryActionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if !audioRecorder.isRecording {
                HStack {
                    Text("または")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(DesignSystem.Colors.border)
                }
                
                PillButton(
                    title: "ファイルから分析",
                    icon: "folder",
                    size: .medium,
                    variant: .secondary
                ) {
                    showingFilePicker = true
                }
                .transition(.opacity)
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
        .onChange(of: showingAnalysisView) { _, isShowing in
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
        // ファイル名のみを保存（絶対パスではなく）
        session.filePath = recordingURL.lastPathComponent
        
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
        // ファイル名のみを保存（絶対パスではなく）
        session.filePath = copiedURL.lastPathComponent
        
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

// MARK: - Modern Audio Level Visualizer
struct ModernAudioLevelVisualizer: View {
    let level: Float
    let isRecording: Bool
    
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Background circle with soft shadow
            Circle()
                .fill(DesignSystem.Colors.surface)
                .frame(width: 200, height: 200)
                .shadow(
                    color: DesignSystem.Colors.shadowMedium,
                    radius: 16,
                    x: 0,
                    y: 8
                )
            
            // Level progress ring
            Circle()
                .stroke(DesignSystem.Colors.border, lineWidth: 8)
                .frame(width: 180, height: 180)
            
            Circle()
                .trim(from: 0, to: CGFloat(level))
                .stroke(
                    isRecording ? DesignSystem.Colors.error : DesignSystem.Colors.primary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.quick, value: level)
            
            // Pulsing center circle when recording
            if isRecording {
                Circle()
                    .fill(DesignSystem.Colors.error.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
            
            // Center icon with background
            Circle()
                .fill(isRecording ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
                .frame(width: 80, height: 80)
                .scaleEffect(animationScale)
                .shadow(
                    color: isRecording ? DesignSystem.Colors.error.opacity(0.3) : DesignSystem.Colors.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textInverse)
        }
        .animation(DesignSystem.Animation.spring, value: isRecording)
        .onAppear {
            if isRecording {
                pulseAnimation = true
            }
        }
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
            withAnimation(DesignSystem.Animation.springBouncy) {
                animationScale = newValue ? 1.1 : 1.0
            }
        }
        .onChange(of: level) { _, _ in
            // Subtle scale animation based on audio level
            if isRecording {
                withAnimation(.easeInOut(duration: 0.1)) {
                    animationScale = 1.0 + (CGFloat(level) * 0.2)
                }
            }
        }
    }
}

// MARK: - Recording Button Component
struct RecordingButton: View {
    let isRecording: Bool
    let hasPermission: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: buttonSize, height: buttonSize)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .shadow(
                        color: shadowColor,
                        radius: isPressed ? 8 : 16,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
                
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignSystem.Animation.spring, value: isPressed)
        .animation(DesignSystem.Animation.standard, value: isRecording)
        .disabled(!hasPermission)
    }
    
    private var buttonSize: CGFloat {
        isRecording ? 100 : 120
    }
    
    private var iconSize: CGFloat {
        isRecording ? 40 : 48
    }
    
    private var backgroundColor: Color {
        if !hasPermission {
            return DesignSystem.Colors.backgroundSecondary
        }
        return isRecording ? DesignSystem.Colors.error : DesignSystem.Colors.primary
    }
    
    private var iconColor: Color {
        if !hasPermission {
            return DesignSystem.Colors.textTertiary
        }
        return DesignSystem.Colors.textInverse
    }
    
    private var iconName: String {
        if !hasPermission {
            return "mic.slash"
        }
        return isRecording ? "stop.fill" : "mic.fill"
    }
    
    private var shadowColor: Color {
        if !hasPermission {
            return DesignSystem.Colors.shadowLight
        }
        return isRecording ? DesignSystem.Colors.error.opacity(0.3) : DesignSystem.Colors.primary.opacity(0.3)
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