import SwiftUI
import CoreData

struct AnalysisResultView: View {
    let analysis: FillerAnalysis
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    // ホームタブに戻るためのクロージャ
    var onComplete: (() -> Void)?
    
    @FetchRequest(
        entity: FillerAnalysis.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FillerAnalysis.analysisDate, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var allAnalyses: FetchedResults<FillerAnalysis>
    
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
    private var previousAnalysis: FillerAnalysis? {
        // 現在の分析より前の最新分析を取得
        guard let currentDate = analysis.analysisDate else { return nil }
        return allAnalyses.first { $0.id != analysis.id && ($0.analysisDate ?? Date()) < currentDate }
    }
    
    private var improvementRate: Double {
        return analysis.calculateImprovement(from: previousAnalysis)
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 25) {
                    // メイン結果表示
                    MainResultCard(
                        fillerCount: Int(analysis.fillerCount),
                        improvementRate: improvementRate,
                        previousCount: previousAnalysis?.fillerCount
                    )
                    
                    // 詳細統計
                    DetailedStatsSection(analysis: analysis)
                    
                    // フィラー語内訳
                    FillerWordsBreakdownSection(analysis: analysis)
                    
                    // 文字起こし全文
                    TranscriptionSection(analysis: analysis)
                    
                    // 改善アドバイス
                    ImprovementAdviceSection(analysis: analysis, improvementRate: improvementRate)
                    
                    // アクションボタン
                    ActionButtonsSection(
                        onShare: {
                            generateShareText()
                            showingShareSheet = true
                        },
                        onNewRecording: {
                            onComplete?() ?? dismiss()
                        },
                        onClose: {
                            onComplete?() ?? dismiss()
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("分析結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        onComplete?() ?? dismiss()
                    }
                }
            }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: shareText)
        }
    }
    
    private func generateShareText() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let transcriptionPreview = analysis.audioSession?.transcription?.prefix(100) ?? ""
        
        shareText = """
        FillarGymでの分析結果 📊
        
        日時: \(dateFormatter.string(from: analysis.analysisDate ?? Date()))
        フィラー語数: \(analysis.fillerCount)個
        フィラー率: \(String(format: "%.1f", analysis.fillerRate))/分
        発話速度: \(String(format: "%.0f", analysis.speakingSpeed))語/分
        
        \(improvementRate >= 0 ? "前回より\(String(format: "%.1f", improvementRate))%改善！🎉" : "前回より\(String(format: "%.1f", abs(improvementRate)))%増加")
        
        発話内容: \(transcriptionPreview)\(transcriptionPreview.count >= 100 ? "..." : "")
        
        #FillarGym #話し方改善
        """
    }
}

struct MainResultCard: View {
    let fillerCount: Int
    let improvementRate: Double
    let previousCount: Int16?
    @State private var animatedCount = 0
    @State private var showImprovement = false
    @State private var cardAppeared = false
    
    var body: some View {
        VStack(spacing: 20) {
            // メインスコア
            VStack(spacing: 8) {
                Text("\(animatedCount)")
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .scaleEffect(cardAppeared ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cardAppeared)
                
                Text("フィラー語")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .opacity(cardAppeared ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.3), value: cardAppeared)
            }
            
            // 比較表示
            if let previous = previousCount {
                HStack(spacing: 15) {
                    VStack {
                        Text("前回")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(previous)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .opacity(showImprovement ? 1.0 : 0.0)
                    .offset(x: showImprovement ? 0 : -20)
                    
                    Image(systemName: improvementRate >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(improvementRate >= 0 ? .green : .red)
                        .scaleEffect(showImprovement ? 1.0 : 0.5)
                        .rotationEffect(.degrees(showImprovement ? 0 : 180))
                    
                    VStack {
                        Text(improvementRate >= 0 ? "改善" : "増加")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(String(format: "%.1f", abs(improvementRate)))%")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(improvementRate >= 0 ? .green : .red)
                    }
                    .opacity(showImprovement ? 1.0 : 0.0)
                    .offset(x: showImprovement ? 0 : 20)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .animation(.easeInOut(duration: 0.7).delay(0.8), value: showImprovement)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
        )
        .onAppear {
            // カード出現アニメーション
            withAnimation(.easeOut(duration: 0.3)) {
                cardAppeared = true
            }
            
            // カウントアップアニメーション
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                animatedCount = fillerCount
            }
            
            // 改善表示アニメーション
            if previousCount != nil {
                withAnimation(.easeInOut(duration: 0.8).delay(0.8)) {
                    showImprovement = true
                }
            }
        }
    }
}

struct DetailedStatsSection: View {
    let analysis: FillerAnalysis
    @State private var statsAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("詳細統計")
                .font(.headline)
                .padding(.horizontal)
                .opacity(statsAppeared ? 1.0 : 0.0)
                .offset(y: statsAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: statsAppeared)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                StatBox(
                    title: "フィラー率",
                    value: "\(String(format: "%.1f", analysis.fillerRate))/分",
                    icon: "timer",
                    color: .orange,
                    animationDelay: 0.2
                )
                
                StatBox(
                    title: "発話速度",
                    value: "\(String(format: "%.0f", analysis.speakingSpeed))語/分",
                    icon: "speedometer",
                    color: .blue,
                    animationDelay: 0.4
                )
                
                StatBox(
                    title: "録音時間",
                    value: "\(String(format: "%.0f", analysis.audioSession?.duration ?? 0))秒",
                    icon: "clock",
                    color: .purple,
                    animationDelay: 0.6
                )
                
                StatBox(
                    title: "分析日時",
                    value: (analysis.analysisDate ?? Date()).formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar",
                    color: .green,
                    animationDelay: 0.8
                )
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                statsAppeared = true
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animationDelay: Double
    @State private var boxAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColor: Color {
        colorScheme == .dark ? color.opacity(0.8) : color
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                adaptiveColor.opacity(0.1),
                adaptiveColor.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(adaptiveColor)
                .scaleEffect(boxAppeared ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(animationDelay), value: boxAppeared)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .opacity(boxAppeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.2), value: boxAppeared)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(boxAppeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.3), value: boxAppeared)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(adaptiveColor.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(boxAppeared ? 1.0 : 0.9)
        .opacity(boxAppeared ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: boxAppeared)
        .onAppear {
            withAnimation {
                boxAppeared = true
            }
        }
    }
}

struct FillerWordsBreakdownSection: View {
    let analysis: FillerAnalysis
    @State private var breakdownAppeared = false
    
    private var fillerWordsArray: [FillerWord] {
        if let fillerWords = analysis.fillerWords {
            return Array(fillerWords as! Set<FillerWord>).sorted { $0.count > $1.count }
        }
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("フィラー語内訳")
                .font(.headline)
                .padding(.horizontal)
                .opacity(breakdownAppeared ? 1.0 : 0.0)
                .offset(y: breakdownAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: breakdownAppeared)
            
            if fillerWordsArray.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                        .scaleEffect(breakdownAppeared ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: breakdownAppeared)
                    
                    Text("フィラー語が検出されませんでした")
                        .foregroundColor(.secondary)
                        .opacity(breakdownAppeared ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: breakdownAppeared)
                    
                    Text("素晴らしいスピーチでした！")
                        .font(.caption)
                        .foregroundColor(.green)
                        .opacity(breakdownAppeared ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.7), value: breakdownAppeared)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(fillerWordsArray.enumerated()), id: \.element.id) { index, fillerWord in
                        FillerWordRow(
                            fillerWord: fillerWord, 
                            totalCount: Int(analysis.fillerCount),
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                breakdownAppeared = true
            }
        }
    }
}

struct FillerWordRow: View {
    let fillerWord: FillerWord
    let totalCount: Int
    let animationDelay: Double
    @State private var progressWidth: CGFloat = 0
    @State private var rowAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(fillerWord.count) / Double(totalCount) * 100
    }
    
    private var progressColor: Color {
        switch percentage {
        case 0..<20: return .green
        case 20..<40: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private var adaptiveProgressColor: Color {
        colorScheme == .dark ? progressColor.opacity(0.8) : progressColor
    }
    
    var body: some View {
        HStack {
            Text(fillerWord.word ?? "不明")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)
                .opacity(rowAppeared ? 1.0 : 0.0)
                .offset(x: rowAppeared ? 0 : -20)
                .animation(.easeOut(duration: 0.4).delay(animationDelay), value: rowAppeared)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                        .opacity(rowAppeared ? 1.0 : 0.3)
                        .animation(.easeOut(duration: 0.3).delay(animationDelay + 0.1), value: rowAppeared)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    adaptiveProgressColor,
                                    adaptiveProgressColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (progressWidth / 100), height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.8).delay(animationDelay + 0.2), value: progressWidth)
                }
                .onAppear {
                    // ジオメトリの幅が決まった後にアニメーション開始
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.2) {
                        progressWidth = percentage
                    }
                }
            }
            .frame(height: 8)
            
            VStack(alignment: .trailing) {
                Text("\(fillerWord.count)回")
                    .font(.caption)
                    .fontWeight(.medium)
                    .opacity(rowAppeared ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.3), value: rowAppeared)
                
                Text("\(String(format: "%.0f", percentage))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(rowAppeared ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.4), value: rowAppeared)
            }
            .frame(width: 50)
            .offset(x: rowAppeared ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.2), value: rowAppeared)
        }
        .padding(.vertical, 4)
        .scaleEffect(rowAppeared ? 1.0 : 0.95)
        .opacity(rowAppeared ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: rowAppeared)
        .onAppear {
            withAnimation {
                rowAppeared = true
            }
        }
    }
}

struct ImprovementAdviceSection: View {
    let analysis: FillerAnalysis
    let improvementRate: Double
    
    private var adviceItems: [AdviceItem] {
        var advice: [AdviceItem] = []
        
        if analysis.fillerCount > 10 {
            advice.append(AdviceItem(
                icon: "lightbulb.fill",
                title: "間を意識しよう",
                description: "フィラー語の代わりに短い間を取ることで、より自然な話し方になります。",
                priority: .high
            ))
        }
        
        if analysis.fillerRate > 5.0 {
            advice.append(AdviceItem(
                icon: "brain.head.profile",
                title: "話す内容を準備",
                description: "事前に話すポイントを整理することで、フィラー語を減らせます。",
                priority: .medium
            ))
        }
        
        if improvementRate >= 0 {
            advice.append(AdviceItem(
                icon: "star.fill",
                title: "素晴らしい改善です！",
                description: "この調子で継続的に練習を続けることで、さらなる改善が期待できます。",
                priority: .low
            ))
        }
        
        advice.append(AdviceItem(
            icon: "repeat",
            title: "継続は力なり",
            description: "週に3回程度の練習を続けることで、確実な改善が見込めます。",
            priority: .low
        ))
        
        return advice
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("改善アドバイス")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(adviceItems, id: \.title) { advice in
                    AdviceRow(advice: advice)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct AdviceItem {
    let icon: String
    let title: String
    let description: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
}

struct AdviceRow: View {
    let advice: AdviceItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: advice.icon)
                .font(.title3)
                .foregroundColor(advice.priority.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(advice.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(advice.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButtonsSection: View {
    let onShare: () -> Void
    let onNewRecording: () -> Void
    let onClose: () -> Void
    @State private var buttonsAppeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var shareButtonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue,
                Color.blue.opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var newRecordingButtonBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                    Text("結果をシェア")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(shareButtonGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(buttonsAppeared ? 1.0 : 0.9)
            .opacity(buttonsAppeared ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.5), value: buttonsAppeared)
            
            Button(action: onNewRecording) {
                HStack {
                    Image(systemName: "mic.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("新しい録音")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(newRecordingButtonBackground)
                .foregroundColor(.primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .scaleEffect(buttonsAppeared ? 1.0 : 0.9)
            .opacity(buttonsAppeared ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.7), value: buttonsAppeared)
            
            Button(action: onClose) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("閉じる")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray4))
                .foregroundColor(.primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
            }
            .scaleEffect(buttonsAppeared ? 1.0 : 0.9)
            .opacity(buttonsAppeared ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.9), value: buttonsAppeared)
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation {
                buttonsAppeared = true
            }
        }
    }
}

struct TranscriptionSection: View {
    let analysis: FillerAnalysis
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var transcriptionText: String {
        analysis.audioSession?.transcription ?? "文字起こしデータがありません"
    }
    
    private var fillerWords: [String] {
        guard let fillerWordsSet = analysis.fillerWords as? Set<FillerWord> else { return [] }
        return Array(fillerWordsSet).compactMap { $0.word }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("文字起こし全文")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "閉じる" : "表示")
                            .font(.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    // 文字起こしテキスト表示
                    ScrollView {
                        Text(highlightedText)
                            .font(.body)
                            .lineSpacing(8)
                            .padding()
                            .frame(maxHeight: 300)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    // コピーボタン
                    Button(action: copyTranscription) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("テキストをコピー")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var highlightedText: AttributedString {
        var attributedString = AttributedString(transcriptionText)
        
        // フィラー語をハイライト
        for fillerWord in fillerWords {
            if let range = attributedString.range(of: fillerWord) {
                attributedString[range].foregroundColor = .red
                attributedString[range].backgroundColor = .red.opacity(0.1)
            }
            
            // 全ての出現箇所をハイライト
            var searchRange = attributedString.startIndex..<attributedString.endIndex
            while let range = attributedString[searchRange].range(of: fillerWord) {
                attributedString[range].foregroundColor = .red
                attributedString[range].backgroundColor = .red.opacity(0.1)
                searchRange = range.upperBound..<attributedString.endIndex
            }
        }
        
        return attributedString
    }
    
    private func copyTranscription() {
        UIPasteboard.general.string = transcriptionText
    }
}

// シェア機能
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}