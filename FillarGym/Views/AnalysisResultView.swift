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
    @State private var contentAppeared = false
    
    private var previousAnalysis: FillerAnalysis? {
        // 現在の分析より前の最新分析を取得
        guard let currentDate = analysis.analysisDate else { return nil }
        return allAnalyses.first { $0.id != analysis.id && ($0.analysisDate ?? Date()) < currentDate }
    }
    
    private var improvementRate: Double {
        return analysis.calculateImprovement(from: previousAnalysis)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    // メイン結果表示
                    ModernMainResultCard(
                        fillerCount: Int(analysis.fillerCount),
                        improvementRate: improvementRate,
                        previousCount: previousAnalysis?.fillerCount
                    )
                    
                    // 詳細統計
                    ModernDetailedStatsSection(analysis: analysis)
                    
                    // フィラー語内訳
                    ModernFillerWordsBreakdownSection(analysis: analysis)
                    
                    // 文字起こし全文
                    ModernTranscriptionSection(analysis: analysis)
                    
                    // 改善アドバイス
                    ModernImprovementAdviceSection(analysis: analysis, improvementRate: improvementRate)
                    
                    // アクションボタン
                    ModernActionButtonsSection(
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
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .opacity(contentAppeared ? 1.0 : 0.0)
                .offset(y: contentAppeared ? 0 : 20)
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
            .navigationTitle("分析結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        onComplete?() ?? dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.standard) {
                contentAppeared = true
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

struct ModernMainResultCard: View {
    let fillerCount: Int
    let improvementRate: Double
    let previousCount: Int16?
    @State private var animatedCount = 0
    @State private var showImprovement = false
    @State private var cardAppeared = false
    
    var body: some View {
        ModernCard(elevation: .high, padding: DesignSystem.Spacing.xl) {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // メインスコア
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("\(animatedCount)")
                        .font(DesignSystem.Typography.numberLarge.weight(.thin))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .scaleEffect(cardAppeared ? 1.0 : 0.8)
                        .animation(DesignSystem.Animation.springBouncy, value: cardAppeared)
                    
                    Text("フィラー語")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .opacity(cardAppeared ? 1.0 : 0.0)
                        .animation(DesignSystem.Animation.standard.delay(0.3), value: cardAppeared)
                }
                
                // 比較表示
                if let previous = previousCount {
                    ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("前回")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                Text("\(previous)")
                                    .font(DesignSystem.Typography.numberMedium)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            .opacity(showImprovement ? 1.0 : 0.0)
                            .offset(x: showImprovement ? 0 : -20)
                            
                            Spacer()
                            
                            TrendIndicator(direction: improvementRate >= 0 ? .down : .up)
                                .scaleEffect(showImprovement ? 1.0 : 0.5)
                                .animation(DesignSystem.Animation.spring.delay(0.5), value: showImprovement)
                            
                            Spacer()
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text(improvementRate >= 0 ? "改善" : "増加")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                Text("\(String(format: "%.1f", abs(improvementRate)))%")
                                    .font(DesignSystem.Typography.numberMedium)
                                    .foregroundColor(improvementRate >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                            }
                            .opacity(showImprovement ? 1.0 : 0.0)
                            .offset(x: showImprovement ? 0 : 20)
                        }
                    }
                    .animation(DesignSystem.Animation.standard.delay(0.8), value: showImprovement)
                }
            }
        }
        .pressAnimation()
        .onAppear {
            withAnimation(DesignSystem.Animation.quick) {
                cardAppeared = true
            }
            
            withAnimation(DesignSystem.Animation.standard.delay(0.2)) {
                animatedCount = fillerCount
            }
            
            if previousCount != nil {
                withAnimation(DesignSystem.Animation.standard.delay(0.8)) {
                    showImprovement = true
                }
            }
        }
    }
}

struct ModernDetailedStatsSection: View {
    let analysis: FillerAnalysis
    @State private var statsAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("詳細統計")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .opacity(statsAppeared ? 1.0 : 0.0)
            .offset(y: statsAppeared ? 0 : 20)
            .animation(DesignSystem.Animation.standard, value: statsAppeared)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2), spacing: DesignSystem.Spacing.md) {
                ModernMetricCard(
                    title: "フィラー率",
                    value: String(format: "%.1f", analysis.fillerRate),
                    subtitle: "/分",
                    color: DesignSystem.Colors.warning,
                    icon: "timer"
                )
                
                ModernMetricCard(
                    title: "発話速度",
                    value: String(format: "%.0f", analysis.speakingSpeed),
                    subtitle: "語/分",
                    color: DesignSystem.Colors.primary,
                    icon: "speedometer"
                )
                
                ModernMetricCard(
                    title: "録音時間",
                    value: String(format: "%.0f", analysis.audioSession?.duration ?? 0),
                    subtitle: "秒",
                    color: DesignSystem.Colors.secondary,
                    icon: "clock"
                )
                
                ModernMetricCard(
                    title: "分析日時",
                    value: (analysis.analysisDate ?? Date()).formatted(date: .abbreviated, time: .omitted),
                    subtitle: nil,
                    color: DesignSystem.Colors.success,
                    icon: "calendar"
                )
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.standard.delay(1.0)) {
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

struct ModernFillerWordsBreakdownSection: View {
    let analysis: FillerAnalysis
    @State private var breakdownAppeared = false
    
    private var fillerWordsArray: [FillerWord] {
        if let fillerWords = analysis.fillerWords {
            return Array(fillerWords as! Set<FillerWord>).sorted { $0.count > $1.count }
        }
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("フィラー語内訳")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .opacity(breakdownAppeared ? 1.0 : 0.0)
            .offset(y: breakdownAppeared ? 0 : 20)
            .animation(DesignSystem.Animation.standard, value: breakdownAppeared)
            
            if fillerWordsArray.isEmpty {
                ModernCard(elevation: .low, padding: DesignSystem.Spacing.xl) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.extraLarge))
                            .foregroundColor(DesignSystem.Colors.success)
                            .scaleEffect(breakdownAppeared ? 1.0 : 0.5)
                            .animation(DesignSystem.Animation.springBouncy.delay(0.3), value: breakdownAppeared)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text("フィラー語が検出されませんでした")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .opacity(breakdownAppeared ? 1.0 : 0.0)
                                .animation(DesignSystem.Animation.standard.delay(0.5), value: breakdownAppeared)
                            
                            Text("素晴らしいスピーチでした！")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.success)
                                .opacity(breakdownAppeared ? 1.0 : 0.0)
                                .animation(DesignSystem.Animation.standard.delay(0.7), value: breakdownAppeared)
                        }
                    }
                }
            } else {
                ModernCard(elevation: .low, padding: DesignSystem.Spacing.lg) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(Array(fillerWordsArray.enumerated()), id: \.element.id) { index, fillerWord in
                            ModernFillerWordRow(
                                fillerWord: fillerWord, 
                                totalCount: Int(analysis.fillerCount),
                                animationDelay: Double(index) * 0.1
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.standard.delay(1.5)) {
                breakdownAppeared = true
            }
        }
    }
}

struct ModernFillerWordRow: View {
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
        HStack(spacing: DesignSystem.Spacing.md) {
            Text(fillerWord.word ?? "不明")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(width: 70, alignment: .leading)
                .opacity(rowAppeared ? 1.0 : 0.0)
                .offset(x: rowAppeared ? 0 : -20)
                .animation(DesignSystem.Animation.standard.delay(animationDelay), value: rowAppeared)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 8)
                        .opacity(rowAppeared ? 1.0 : 0.3)
                        .animation(DesignSystem.Animation.quick.delay(animationDelay + 0.1), value: rowAppeared)
                    
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
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
                        .animation(DesignSystem.Animation.standard.delay(animationDelay + 0.2), value: progressWidth)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.2) {
                        progressWidth = percentage
                    }
                }
            }
            .frame(height: 8)
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                Text("\(fillerWord.count)回")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .opacity(rowAppeared ? 1.0 : 0.0)
                    .animation(DesignSystem.Animation.standard.delay(animationDelay + 0.3), value: rowAppeared)
                
                Text("\(String(format: "%.0f", percentage))%")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .opacity(rowAppeared ? 1.0 : 0.0)
                    .animation(DesignSystem.Animation.standard.delay(animationDelay + 0.4), value: rowAppeared)
            }
            .frame(width: 50)
            .offset(x: rowAppeared ? 0 : 20)
            .animation(DesignSystem.Animation.standard.delay(animationDelay + 0.2), value: rowAppeared)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .scaleEffect(rowAppeared ? 1.0 : 0.95)
        .opacity(rowAppeared ? 1.0 : 0.0)
        .animation(DesignSystem.Animation.standard.delay(animationDelay), value: rowAppeared)
        .onAppear {
            withAnimation {
                rowAppeared = true
            }
        }
    }
}

struct ModernImprovementAdviceSection: View {
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("改善アドバイス")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(adviceItems, id: \.title) { advice in
                    ModernAdviceRow(advice: advice)
                }
            }
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

struct ModernAdviceRow: View {
    let advice: AdviceItem
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.md) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                Image(systemName: advice.icon)
                    .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                    .foregroundColor(advice.priority.color)
                    .frame(width: DesignSystem.IconSize.large)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(advice.title)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(advice.description)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
        .pressAnimation()
    }
}

struct ModernActionButtonsSection: View {
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
        VStack(spacing: DesignSystem.Spacing.md) {
            PillButton(
                title: "結果をシェア",
                icon: "square.and.arrow.up",
                size: .large,
                variant: .primary
            ) {
                onShare()
            }
            .scaleEffect(buttonsAppeared ? 1.0 : 0.9)
            .opacity(buttonsAppeared ? 1.0 : 0.0)
            .animation(DesignSystem.Animation.springBouncy.delay(2.5), value: buttonsAppeared)
            
            PillButton(
                title: "新しい録音",
                icon: "mic.circle",
                size: .large,
                variant: .secondary
            ) {
                onNewRecording()
            }
            .scaleEffect(buttonsAppeared ? 1.0 : 0.9)
            .opacity(buttonsAppeared ? 1.0 : 0.0)
            .animation(DesignSystem.Animation.springBouncy.delay(2.7), value: buttonsAppeared)
            
            PillButton(
                title: "閉じる",
                icon: "xmark.circle",
                size: .large,
                variant: .ghost
            ) {
                onClose()
            }
            .scaleEffect(buttonsAppeared ? 1.0 : 0.9)
            .opacity(buttonsAppeared ? 1.0 : 0.0)
            .animation(DesignSystem.Animation.springBouncy.delay(2.9), value: buttonsAppeared)
        }
        .onAppear {
            withAnimation {
                buttonsAppeared = true
            }
        }
    }
}

struct ModernTranscriptionSection: View {
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("文字起こし全文")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(DesignSystem.Animation.quick) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(isExpanded ? "閉じる" : "表示")
                            .font(DesignSystem.Typography.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    ModernCard(elevation: .low, padding: DesignSystem.Spacing.md) {
                        ScrollView {
                            Text(highlightedText)
                                .font(DesignSystem.Typography.body)
                                .lineSpacing(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(maxHeight: 300)
                        }
                    }
                    
                    PillButton(
                        title: "テキストをコピー",
                        icon: "doc.on.doc",
                        size: .medium,
                        variant: .outline
                    ) {
                        copyTranscription()
                    }
                }
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