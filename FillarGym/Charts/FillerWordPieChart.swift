import SwiftUI
import Charts

/// フィラー語種別分布を表示する円グラフコンポーネント
struct FillerWordPieChart: View {
    let analyses: [FillerAnalysis]
    @State private var animateChart = false
    @State private var selectedSegment: FillerWordDistribution?
    @State private var showPercentages = true
    
    private var distributionData: [FillerWordDistribution] {
        analyses.toDistributionData()
    }
    
    private var totalCount: Int {
        distributionData.map { $0.count }.reduce(0, +)
    }
    
    // カラーパレット
    private let chartColors: [Color] = [
        DesignSystem.Colors.secondary, // Primary Blue
        DesignSystem.Colors.primary, // Dark Navy
        DesignSystem.Colors.accent, // Gold
        DesignSystem.Colors.secondaryLight, // Light Blue
        DesignSystem.Colors.secondaryDark, // Royal Blue
        DesignSystem.Colors.primaryDark, // Darker Navy
        DesignSystem.Colors.accentLight, // Light Gold
        DesignSystem.Colors.primaryLight  // Medium Blue
    ]
    
    var body: some View {
        ModernCard(elevation: .medium, isPremium: true) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("フィラー語分布")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("合計: \(totalCount)回")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // パーセンテージ表示切り替え
                    if !distributionData.isEmpty {
                        Toggle("", isOn: $showPercentages)
                            .toggleStyle(CompactToggleStyle(label: "%"))
                            .scaleEffect(0.8)
                    }
                }
                
                // チャートコンテンツ
                if distributionData.isEmpty {
                    EmptyChartView(
                        icon: "chart.pie.fill",
                        title: "データがありません",
                        message: "録音を行うとフィラー語の分布が表示されます"
                    )
                } else {
                    HStack(spacing: 20) {
                        // 円グラフ
                        ZStack {
                            Chart(distributionData) { data in
                                SectorMark(
                                    angle: .value("回数", animateChart ? data.count : 0),
                                    innerRadius: .ratio(0.4),
                                    angularInset: 2
                                )
                                .foregroundStyle(colorFor(data: data))
                                .opacity(selectedSegment?.id == data.id ? 1.0 : (selectedSegment == nil ? 0.9 : 0.5))
                            }
                            .frame(width: 160, height: 160)
                            .chartBackground { _ in
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                DesignSystem.Colors.surface.opacity(0.1),
                                                DesignSystem.Colors.surface.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .onTapGesture {
                                handlePieChartTap()
                            }
                            
                            // 中央の統計表示
                            if let selectedSegment = selectedSegment {
                                CenterDisplayView(data: selectedSegment, showPercentages: showPercentages)
                            } else {
                                CenterSummaryView(totalCount: totalCount, itemCount: distributionData.count)
                            }
                        }
                        
                        // 凡例とリスト
                        VStack(alignment: .leading, spacing: 8) {
                            Text("詳細")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 6) {
                                    ForEach(Array(distributionData.enumerated()), id: \.element.id) { index, data in
                                        FillerWordRow(
                                            data: data,
                                            color: chartColors[index % chartColors.count],
                                            isSelected: selectedSegment?.id == data.id,
                                            showPercentages: showPercentages
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedSegment = selectedSegment?.id == data.id ? nil : data
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 分析インサイト
                    if distributionData.count >= 2 {
                        InsightView(data: distributionData)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: ChartConfig.animationDuration).delay(0.3)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func colorFor(data: FillerWordDistribution) -> Color {
        if let index = distributionData.firstIndex(where: { $0.id == data.id }) {
            return chartColors[index % chartColors.count]
        }
        return DesignSystem.Colors.primary
    }
    
    private func handlePieChartTap() {
        // 簡易的なタップ処理 - ランダムなセグメントを選択
        if !distributionData.isEmpty {
            let randomIndex = Int.random(in: 0..<distributionData.count)
            let randomData = distributionData[randomIndex]
            
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedSegment = selectedSegment?.id == randomData.id ? nil : randomData
            }
        }
    }
}

// MARK: - Supporting Views

struct CenterDisplayView: View {
    let data: FillerWordDistribution
    let showPercentages: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(data.word)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if showPercentages {
                Text(String(format: "%.1f%%", data.percentage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.secondary)
            } else {
                Text("\(data.count)回")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.secondary)
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
}

struct CenterSummaryView: View {
    let totalCount: Int
    let itemCount: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(totalCount)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("総回数")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("\(itemCount)種類")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct FillerWordRow: View {
    let data: FillerWordDistribution
    let color: Color
    let isSelected: Bool
    let showPercentages: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // カラーインジケーター
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .scaleEffect(isSelected ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
            
            // フィラー語名
            Text(data.word)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // 数値表示
            if showPercentages {
                Text(String(format: "%.1f%%", data.percentage))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                Text("\(data.count)回")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? color.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? color : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct InsightView: View {
    let data: [FillerWordDistribution]
    
    private var mostUsedWord: FillerWordDistribution? {
        data.max { $0.count < $1.count }
    }
    
    private var diversityScore: String {
        let maxCount = data.map { $0.count }.max() ?? 1
        let totalCount = data.map { $0.count }.reduce(0, +)
        let dominance = Double(maxCount) / Double(totalCount)
        
        if dominance > 0.6 {
            return "特定のフィラー語に偏りがあります"
        } else if dominance > 0.4 {
            return "バランスよく分散しています"
        } else {
            return "多様なフィラー語を使用しています"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分析結果")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let mostUsed = mostUsedWord {
                    InsightRow(
                        icon: "star.fill",
                        text: "最も多い: 「\(mostUsed.word)」(\(mostUsed.count)回)",
                        color: DesignSystem.Colors.accent
                    )
                }
                
                InsightRow(
                    icon: "chart.bar.fill",
                    text: diversityScore,
                    color: DesignSystem.Colors.secondary
                )
                
                InsightRow(
                    icon: "lightbulb.fill",
                    text: "意識的に間を取ることで改善できます",
                    color: DesignSystem.Colors.primary
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignSystem.Colors.surface.opacity(0.3),
                            DesignSystem.Colors.surface.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct CompactToggleStyle: ToggleStyle {
    let label: String
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            RoundedRectangle(cornerRadius: 10)
                .fill(configuration.isOn ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary.opacity(0.3))
                .frame(width: 32, height: 16)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: configuration.isOn ? 6 : -6)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

#Preview {
    FillerWordPieChart(analyses: [])
        .padding()
}