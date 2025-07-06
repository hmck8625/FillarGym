import SwiftUI
import CoreData
import Charts
import AVFoundation

struct SessionDetailView: View {
    let session: AudioSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var playbackTimer: Timer?
    @State private var isDataLoaded = false
    
    private var transcriptionText: String {
        session.transcription ?? "文字起こしデータがありません"
    }
    
    private var totalCharacterCount: Int {
        transcriptionText.count
    }
    
    private var wordsPerMinute: Int {
        let minutes = session.duration / 60.0
        return minutes > 0 ? Int(Double(totalCharacterCount) / minutes) : 0
    }
    
    private var fillerWords: [FillerWord] {
        guard let analysis = session.analysis,
              let fillerWords = analysis.fillerWords as? Set<FillerWord> else {
            return []
        }
        return Array(fillerWords).sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isDataLoaded {
                    ScrollView {
                        VStack(spacing: 0) {
                            // デバッグ情報（開発用）
                            if ProcessInfo.processInfo.environment["DEBUG_MODE"] == "true" {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DEBUG INFO:")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text("Session ID: \(session.id?.uuidString ?? "nil")")
                                        .font(.caption2)
                                    Text("Title: \(session.title ?? "nil")")
                                        .font(.caption2)
                                    Text("Transcription: \(transcriptionText.prefix(50))...")
                                        .font(.caption2)
                                    Text("Analysis: \(session.analysis?.id?.uuidString ?? "nil")")
                                        .font(.caption2)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                            }
                            
                            // ヘッダー情報
                            HeaderSection(
                                session: session,
                                totalCharacterCount: totalCharacterCount,
                                wordsPerMinute: wordsPerMinute,
                                isPlaying: $isPlaying,
                                playbackProgress: $playbackProgress,
                                onPlayPause: togglePlayback
                            )
                            
                            // タブ選択
                            Picker("表示内容", selection: $selectedTab) {
                                Text("文字起こし").tag(0)
                                Text("分析結果").tag(1)
                                Text("統計").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            
                            // タブコンテンツ
                            switch selectedTab {
                            case 0:
                                TranscriptionTab(
                                    transcription: transcriptionText,
                                    fillerWords: fillerWords
                                )
                            case 1:
                                AnalysisTab(
                                    analysis: session.analysis,
                                    fillerWords: fillerWords
                                )
                            case 2:
                                StatisticsTab(
                                    session: session,
                                    analysis: session.analysis
                                )
                            default:
                                EmptyView()
                            }
                        }
                    }
                } else {
                    // ローディング表示
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("データを読み込み中...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignSystem.Colors.background)
                }
            }
            .navigationTitle("セッション詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(item: generateShareText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            print("=== SessionDetailView onAppear START ===")
            print("🚀 View appeared at: \(Date())")
            
            // Core Data状態の確認
            print("\n📊 Core Data State:")
            print("  - Session isDeleted: \(session.isDeleted)")
            print("  - Session managedObjectContext: \(session.managedObjectContext != nil)")
            print("  - Environment viewContext: \(viewContext)")
            
            // 詳細なデバッグ出力
            print("\n📊 Session Basic Info:")
            print("  - Session ID: \(session.id?.uuidString ?? "nil")")
            print("  - Title: \(session.title ?? "nil")")
            print("  - Duration: \(session.duration) seconds")
            print("  - Created: \(session.createdAt?.formatted() ?? "nil")")
            print("  - File Path: \(session.filePath ?? "nil")")
            
            print("\n📝 Transcription Info:")
            print("  - Has transcription: \(session.transcription != nil)")
            print("  - Transcription length: \(transcriptionText.count) characters")
            print("  - First 100 chars: \(String(transcriptionText.prefix(100)))")
            
            print("\n📈 Analysis Info:")
            print("  - Has analysis: \(session.analysis != nil)")
            if let analysis = session.analysis {
                print("  - Analysis ID: \(analysis.id?.uuidString ?? "nil")")
                print("  - Analysis isDeleted: \(analysis.isDeleted)")
                print("  - Analysis managedObjectContext: \(analysis.managedObjectContext != nil)")
                print("  - Filler count: \(analysis.fillerCount)")
                print("  - Filler rate: \(analysis.fillerRate)")
                print("  - Speaking speed: \(analysis.speakingSpeed)")
                print("  - Analysis date: \(analysis.analysisDate?.formatted() ?? "nil")")
            }
            
            print("\n🎯 Filler Words Info:")
            print("  - Total filler words: \(fillerWords.count)")
            for (index, word) in fillerWords.enumerated().prefix(5) {
                print("  - [\(index)] \(word.word ?? "nil"): \(word.count) times")
            }
            
            print("\n⏱️ Starting data load delay...")
            
            // データ読み込み完了を少し遅延させて、Core Dataが準備できるようにする
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("⏱️ Data load delay completed, setting isDataLoaded = true")
                withAnimation {
                    isDataLoaded = true
                }
                print("✅ isDataLoaded set to: \(isDataLoaded)")
                print("=== SessionDetailView onAppear END ===\n")
            }
        }
        .onDisappear {
            // クリーンアップ
            stopPlayback()
        }
        .onChange(of: isDataLoaded) { _, newValue in
            print("📊 isDataLoaded changed to: \(newValue)")
        }
    }
    
    // MARK: - Audio Playback Methods
    
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            playAudio()
        }
    }
    
    private func playAudio() {
        guard let filePath = session.filePath else {
            print("❌ No audio file path available")
            return
        }
        
        // filePathが絶対パスか相対パスかを判定
        let audioURL: URL
        if filePath.hasPrefix("/") {
            // 絶対パスの場合はそのまま使用
            audioURL = URL(fileURLWithPath: filePath)
        } else {
            // 相対パスの場合はDocumentsディレクトリに追加
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            audioURL = documentsPath.appendingPathComponent(filePath)
        }
        
        print("🎵 Attempting to play audio from: \(audioURL.path)")
        
        // ファイルの存在確認
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("❌ Audio file not found at path: \(audioURL.path)")
            // デバッグ用：Documentsディレクトリの内容を表示
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
                    print("📁 Documents directory contents:")
                    for file in contents {
                        print("  - \(file.lastPathComponent)")
                    }
                } catch {
                    print("❌ Error listing documents directory: \(error)")
                }
            }
            return
        }
        
        do {
            // オーディオセッションの設定
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // プレイヤーの初期化
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            
            // プログレス更新タイマー
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = audioPlayer {
                    playbackProgress = player.currentTime / player.duration
                    
                    // 再生終了時
                    if !player.isPlaying && playbackProgress >= 0.99 {
                        stopPlayback()
                    }
                }
            }
            
            print("✅ Audio playback started successfully")
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }
    
    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        print("⏸️ Audio playback paused")
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
        print("⏹️ Audio playback stopped")
    }
    
    private func generateShareText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return """
        【FillarGym録音セッション】
        
        タイトル: \(session.title ?? "無題")
        日時: \(dateFormatter.string(from: session.createdAt ?? Date()))
        録音時間: \(String(format: "%.1f", session.duration / 60))分
        
        📊 統計情報
        ・全文字数: \(totalCharacterCount)文字
        ・発話速度: \(wordsPerMinute)文字/分
        ・フィラー語数: \(session.analysis?.fillerCount ?? 0)個
        ・フィラー率: \(String(format: "%.1f", session.analysis?.fillerRate ?? 0))/分
        
        📝 文字起こし（抜粋）
        \(String(transcriptionText.prefix(200)))...
        
        #FillarGym #話し方改善
        """
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    let session: AudioSession
    let totalCharacterCount: Int
    let wordsPerMinute: Int
    @Binding var isPlaying: Bool
    @Binding var playbackProgress: Double
    let onPlayPause: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトルと日時
            VStack(spacing: 8) {
                Text(session.title ?? "録音セッション")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(session.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 主要統計
            HStack(spacing: 20) {
                SessionStatCard(
                    value: String(format: "%.1f", session.duration / 60),
                    label: "分",
                    icon: "clock.fill",
                    color: .blue
                )
                
                SessionStatCard(
                    value: "\(totalCharacterCount)",
                    label: "文字",
                    icon: "text.alignleft",
                    color: .green
                )
                
                SessionStatCard(
                    value: "\(wordsPerMinute)",
                    label: "文字/分",
                    icon: "speedometer",
                    color: .orange
                )
                
                if let analysis = session.analysis {
                    SessionStatCard(
                        value: "\(analysis.fillerCount)",
                        label: "フィラー",
                        icon: "exclamationmark.bubble.fill",
                        color: .red
                    )
                }
            }
            
            // 録音再生コントロール
            if session.filePath != nil {
                VStack(spacing: 12) {
                    // 再生ボタン
                    Button(action: onPlayPause) {
                        HStack(spacing: 12) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            DesignSystem.Colors.secondary,
                                            DesignSystem.Colors.primary
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isPlaying ? "一時停止" : "録音を再生")
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text(String(format: "%.1f分", session.duration / 60))
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // プログレスバー
                    if isPlaying || playbackProgress > 0 {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // 背景
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(DesignSystem.Colors.surfaceElevated)
                                    .frame(height: 4)
                                
                                // プログレス
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                DesignSystem.Colors.secondary,
                                                DesignSystem.Colors.primary
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * playbackProgress, height: 4)
                                    .animation(.linear(duration: 0.1), value: playbackProgress)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Colors.surface)
                        .shadow(color: DesignSystem.Colors.shadowLight, radius: 8, x: 0, y: 2)
                )
            }
        }
        .padding()
        .background(backgroundGradient)
    }
}

// MARK: - Session Stat Card
struct SessionStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(appeared ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

// MARK: - Transcription Tab
struct TranscriptionTab: View {
    let transcription: String
    let fillerWords: [FillerWord]
    @State private var highlightFillers = true
    @State private var textSize: CGFloat = 16
    
    private var highlightedText: AttributedString {
        var attributedString = AttributedString(transcription)
        
        if highlightFillers {
            for fillerWord in fillerWords {
                guard let word = fillerWord.word else { continue }
                
                var searchRange = attributedString.startIndex..<attributedString.endIndex
                while let range = attributedString[searchRange].range(of: word) {
                    attributedString[range].foregroundColor = .red
                    attributedString[range].backgroundColor = .red.opacity(0.1)
                    searchRange = range.upperBound..<attributedString.endIndex
                }
            }
        }
        
        return attributedString
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if transcription == "文字起こしデータがありません" || transcription.isEmpty {
                // 空のコンテンツ状態
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("文字起こしデータがありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("このセッションはまだ分析されていないか、\n文字起こし処理が失敗している可能性があります。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // コントロール
                HStack {
                    Toggle("フィラー語をハイライト", isOn: $highlightFillers)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: { textSize = max(12, textSize - 2) }) {
                            Image(systemName: "textformat.size.smaller")
                        }
                        
                        Text("\(Int(textSize))pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                        
                        Button(action: { textSize = min(24, textSize + 2) }) {
                            Image(systemName: "textformat.size.larger")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal)
                
                // 文字起こしテキスト
                ScrollView {
                    Text(highlightedText)
                        .font(.system(size: textSize))
                        .lineSpacing(8)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.3), value: highlightFillers)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .frame(minHeight: 200)
                
                // コピーボタン
                Button(action: copyTranscription) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("テキストをコピー")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func copyTranscription() {
        UIPasteboard.general.string = transcription
    }
}

// MARK: - Analysis Tab
struct AnalysisTab: View {
    let analysis: FillerAnalysis?
    let fillerWords: [FillerWord]
    
    var body: some View {
        VStack(spacing: 20) {
            if analysis != nil {
                // フィラー語分布
                FillerDistributionCard(fillerWords: fillerWords)
                
                // 改善提案（デモ用の固定データ）
                let demoSuggestions = [
                    "間を意識して話すことで、フィラー語を減らせます",
                    "話す内容を事前に整理すると効果的です",
                    "ゆっくりと話すことを心がけましょう"
                ]
                ImprovementSuggestionsCard(suggestions: demoSuggestions)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("分析データがありません")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
        .padding()
    }
}

// MARK: - Filler Distribution Card
struct FillerDistributionCard: View {
    let fillerWords: [FillerWord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("フィラー語分布")
                .font(.headline)
            
            if !fillerWords.isEmpty {
                ForEach(Array(fillerWords.prefix(10)), id: \.id) { fillerWord in
                    HStack {
                        Text(fillerWord.word ?? "")
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 24)
                                    .cornerRadius(12)
                                
                                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: geometry.size.width * (Double(fillerWord.count) / Double(fillerWords.first?.count ?? 1)), height: 24)
                                    .cornerRadius(12)
                                    .animation(.easeInOut(duration: 0.5), value: fillerWord.count)
                            }
                        }
                        .frame(height: 24)
                        
                        Text("\(fillerWord.count)回")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            } else {
                Text("フィラー語が検出されませんでした")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
    }
}

// MARK: - Improvement Suggestions Card
struct ImprovementSuggestionsCard: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("改善アドバイス")
                .font(.headline)
            
            ForEach(suggestions.filter { !$0.isEmpty }, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    
                    Text(suggestion)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
    }
}

// MARK: - Statistics Tab
struct StatisticsTab: View {
    let session: AudioSession
    let analysis: FillerAnalysis?
    
    var body: some View {
        VStack(spacing: 20) {
            if let analysis = analysis {
                // フィラー率の時系列グラフ
                FillerRateChart()
                    .environment(\.managedObjectContext, session.managedObjectContext ?? PersistenceController.shared.container.viewContext)
                
                // 詳細統計
                DetailedStatisticsCard(session: session, analysis: analysis)
            } else {
                Text("統計データがありません")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

// MARK: - Filler Rate Chart
struct FillerRateChart: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var sessions: [AudioSession] = []
    @State private var animateChart = false
    
    private var chartData: [(date: Date, rate: Double)] {
        sessions.compactMap { session in
            guard let analysis = session.analysis,
                  let date = session.createdAt else { return nil }
            return (date: date, rate: analysis.fillerRate)
        }.suffix(10) // 最新10件のデータを表示
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("フィラー率の推移")
                .font(.headline)
            
            if chartData.isEmpty {
                // データがない場合
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Colors.surfaceElevated)
                        .frame(height: 200)
                    
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text("履歴データがありません")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            } else {
                // チャート表示
                Chart {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                        LineMark(
                            x: .value("日付", data.date),
                            y: .value("フィラー率", animateChart ? data.rate : 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignSystem.Colors.secondary,
                                    DesignSystem.Colors.primary
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("日付", data.date),
                            y: .value("フィラー率", animateChart ? data.rate : 0)
                        )
                        .foregroundStyle(DesignSystem.Colors.secondary)
                        .symbolSize(50)
                    }
                    
                    // 平均線
                    if !chartData.isEmpty {
                        let average = chartData.map { $0.rate }.reduce(0, +) / Double(chartData.count)
                        RuleMark(y: .value("平均", average))
                            .foregroundStyle(DesignSystem.Colors.accent.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("平均: \(String(format: "%.1f", average))")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .padding(.horizontal, 4)
                                    .background(DesignSystem.Colors.surface)
                                    .cornerRadius(4)
                            }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animateChart = true
                    }
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
        .shadow(color: DesignSystem.Colors.shadowLight, radius: 10, x: 0, y: 2)
        .onAppear {
            loadSessions()
        }
    }
    
    private func loadSessions() {
        let request: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: true)]
        request.predicate = NSPredicate(format: "analysis != nil")
        
        do {
            sessions = try viewContext.fetch(request)
        } catch {
            print("❌ Error fetching sessions: \(error)")
        }
    }
}

// MARK: - Detailed Statistics Card
struct DetailedStatisticsCard: View {
    let session: AudioSession
    let analysis: FillerAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細統計")
                .font(.headline)
            
            VStack(spacing: 12) {
                SessionStatRow(title: "録音日時", value: session.createdAt?.formatted() ?? "")
                SessionStatRow(title: "録音時間", value: String(format: "%.1f分", session.duration / 60))
                SessionStatRow(title: "フィラー語総数", value: "\(analysis.fillerCount)個")
                SessionStatRow(title: "フィラー率", value: String(format: "%.1f個/分", analysis.fillerRate))
                SessionStatRow(title: "発話速度", value: String(format: "%.0f文字/分", analysis.speakingSpeed))
                SessionStatRow(title: "分析日時", value: analysis.analysisDate?.formatted() ?? "")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
    }
}

struct SessionStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}