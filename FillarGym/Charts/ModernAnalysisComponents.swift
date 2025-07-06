import SwiftUI
import Charts

// MARK: - Modern Statistics Cards

struct ModernStatisticsCards: View {
    let analyses: [FillerAnalysis]
    
    private var averageFillerCount: Double {
        guard !analyses.isEmpty else { return 0 }
        return analyses.map { Double($0.fillerCount) }.reduce(0, +) / Double(analyses.count)
    }
    
    private var improvementRate: Double {
        guard analyses.count >= 2 else { return 0 }
        let recent = analyses.suffix(3).map { Double($0.fillerCount) }.reduce(0, +) / Double(min(3, analyses.count))
        let older = analyses.prefix(3).map { Double($0.fillerCount) }.reduce(0, +) / Double(min(3, analyses.count))
        
        if older == 0 { return 0 }
        return ((older - recent) / older) * 100
    }
    
    private var averageFillerRate: Double {
        guard !analyses.isEmpty else { return 0 }
        return analyses.map { $0.fillerRate }.reduce(0, +) / Double(analyses.count)
    }
    
    private var bestRecord: Int {
        Int(analyses.min(by: { $0.fillerCount < $1.fillerCount })?.fillerCount ?? 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // ヘッダー
            HStack {
                Text("統計サマリー")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondary)
            }
            
            // 統計カード
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.md) {
                ModernStatCard(
                    title: "平均フィラー数",
                    value: String(format: "%.1f", averageFillerCount),
                    unit: "回",
                    color: DesignSystem.Colors.secondary,
                    icon: "number.circle.fill"
                )
                
                ModernStatCard(
                    title: "改善率",
                    value: String(format: "%.1f", abs(improvementRate)),
                    unit: "%",
                    color: improvementRate >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error,
                    icon: improvementRate >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                )
                
                ModernStatCard(
                    title: "総録音数",
                    value: "\(analyses.count)",
                    unit: "回",
                    color: DesignSystem.Colors.primary,
                    icon: "waveform.circle.fill"
                )
                
                ModernStatCard(
                    title: "最良記録",
                    value: "\(bestRecord)",
                    unit: "回",
                    color: DesignSystem.Colors.accent,
                    icon: "star.circle.fill"
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            ModernCard(elevation: .medium, isPremium: true) {
                EmptyView()
            }
        )
    }
}

// MARK: - Modern Stat Card

struct ModernStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // アイコンとタイトル
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            // 数値とタイトル
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignSystem.Colors.surface,
                            DesignSystem.Colors.surface.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: DesignSystem.Colors.shadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Modern Improvement Suggestions

struct ModernImprovementSuggestions: View {
    let analyses: [FillerAnalysis]
    
    private var suggestions: [ImprovementSuggestion] {
        var result: [ImprovementSuggestion] = []
        
        // 基本的な提案
        result.append(ImprovementSuggestion(
            icon: "lightbulb.fill",
            title: "間を活用しよう",
            description: "フィラー語の代わりに短い間を取ることで、より説得力のある話し方になります。",
            priority: .medium,
            category: .technique
        ))
        
        // データに基づいた提案
        if !analyses.isEmpty {
            let averageFillerCount = analyses.map { Double($0.fillerCount) }.reduce(0, +) / Double(analyses.count)
            
            if averageFillerCount > 10 {
                result.append(ImprovementSuggestion(
                    icon: "brain.head.profile",
                    title: "話す内容を事前整理",
                    description: "フィラー語が多めです。話すポイントを事前に整理することで、フィラー語の使用を減らせます。",
                    priority: .high,
                    category: .preparation
                ))
            }
            
            if analyses.count < 5 {
                result.append(ImprovementSuggestion(
                    icon: "timer",
                    title: "練習を続けよう",
                    description: "継続的な練習が改善の鍵です。週に3回の録音を目標にしましょう。",
                    priority: .medium,
                    category: .practice
                ))
            }
            
            // 改善傾向の分析
            if analyses.count >= 3 {
                let recent = analyses.suffix(3).map { $0.fillerCount }.reduce(0, +) / 3
                let older = analyses.prefix(3).map { $0.fillerCount }.reduce(0, +) / 3
                
                if recent > older {
                    result.append(ImprovementSuggestion(
                        icon: "exclamationmark.triangle.fill",
                        title: "練習方法を見直そう",
                        description: "最近フィラー語が増えています。録音環境や練習方法を見直してみましょう。",
                        priority: .high,
                        category: .analysis
                    ))
                } else if recent < older {
                    result.append(ImprovementSuggestion(
                        icon: "star.fill",
                        title: "順調に改善中！",
                        description: "フィラー語が減っています。この調子で練習を続けましょう。",
                        priority: .low,
                        category: .encouragement
                    ))
                }
            }
        }
        
        return Array(result.prefix(3)) // 最大3つまで表示
    }
    
    var body: some View {
        ModernCard(elevation: .medium, isPremium: true) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // ヘッダー
                HStack {
                    Text("改善提案")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                
                // 提案リスト
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ForEach(suggestions, id: \.id) { suggestion in
                        ModernSuggestionRow(suggestion: suggestion)
                        
                        if suggestion.id != suggestions.last?.id {
                            Divider()
                                .background(DesignSystem.Colors.textSecondary.opacity(0.2))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct ImprovementSuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let priority: Priority
    let category: Category
    
    enum Priority {
        case high, medium, low
    }
    
    enum Category {
        case technique, preparation, practice, analysis, encouragement
    }
}

struct ModernSuggestionRow: View {
    let suggestion: ImprovementSuggestion
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // アイコン
            ZStack {
                Circle()
                    .fill(priorityColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: suggestion.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(priorityColor)
            }
            
            // コンテンツ
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(suggestion.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    // 優先度インジケーター
                    if suggestion.priority == .high {
                        Text("重要")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.error)
                            .cornerRadius(8)
                    }
                }
                
                Text(suggestion.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .high:
            return DesignSystem.Colors.error
        case .medium:
            return DesignSystem.Colors.warning
        case .low:
            return DesignSystem.Colors.success
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ModernStatisticsCards(analyses: [])
        ModernImprovementSuggestions(analyses: [])
    }
    .padding()
}