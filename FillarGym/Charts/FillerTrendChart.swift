import SwiftUI
import Charts

/// フィラー語推移を表示する線グラフコンポーネント
struct FillerTrendChart: View {
    let analyses: [FillerAnalysis]
    @State private var animateChart = false
    @State private var selectedData: FillerTrendData?
    
    private var trendData: [FillerTrendData] {
        analyses.toTrendData()
    }
    
    private var maxFillerCount: Int {
        trendData.map { $0.fillerCount }.max() ?? 10
    }
    
    var body: some View {
        ModernCard(elevation: .medium, isPremium: true) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("フィラー語推移")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("録音回数: \(trendData.count)回")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // 改善インジケーター
                    if let improvement = calculateImprovement() {
                        ImprovementIndicator(improvement: improvement)
                    }
                }
                
                // チャートコンテンツ
                if trendData.isEmpty {
                    EmptyChartView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "データがありません",
                        message: "録音を行うと推移が表示されます"
                    )
                } else {
                    // 選択されたデータの詳細表示
                    if let selectedData = selectedData {
                        SelectedDataView(data: selectedData)
                    }
                    
                    // メインチャート
                    Chart {
                        ForEach(trendData) { data in
                            // メインライン
                            LineMark(
                                x: .value("日付", data.date),
                                y: .value("フィラー語数", animateChart ? data.fillerCount : 0)
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
                            
                            // データポイント
                            PointMark(
                                x: .value("日付", data.date),
                                y: .value("フィラー語数", animateChart ? data.fillerCount : 0)
                            )
                            .foregroundStyle(DesignSystem.Colors.secondary)
                            .symbolSize(selectedData?.id == data.id ? 80 : 50)
                            .opacity(selectedData?.id == data.id ? 1.0 : 0.8)
                            
                            // 選択時のハイライト
                            if let selectedData = selectedData, selectedData.id == data.id {
                                RuleMark(x: .value("日付", data.date))
                                    .foregroundStyle(DesignSystem.Colors.accent.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            }
                        }
                    }
                    .frame(height: ChartConfig.chartHeight)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { _ in
                            AxisValueLabel()
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .chartBackground { _ in
                        Rectangle()
                            .fill(DesignSystem.Colors.surface.opacity(0.1))
                    }
                    .onTapGesture { location in
                        handleSimpleTap(location: location)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: ChartConfig.animationDuration)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateImprovement() -> Double? {
        guard trendData.count >= 2 else { return nil }
        
        let recent = trendData.suffix(3)
        let older = trendData.prefix(3)
        
        let recentAverage = recent.map { $0.fillerCount }.reduce(0, +) / recent.count
        let olderAverage = older.map { $0.fillerCount }.reduce(0, +) / older.count
        
        guard olderAverage > 0 else { return nil }
        
        return Double(olderAverage - recentAverage) / Double(olderAverage) * 100
    }
    
    private func handleSimpleTap(location: CGPoint) {
        // 簡易的なタップ処理
        if !trendData.isEmpty {
            let randomIndex = Int.random(in: 0..<trendData.count)
            let randomData = trendData[randomIndex]
            
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedData = selectedData?.id == randomData.id ? nil : randomData
            }
        }
    }
    
    private func findNearestData(relativePosition: Double) -> FillerTrendData? {
        guard !trendData.isEmpty else { return nil }
        
        let index = Int(relativePosition * Double(trendData.count))
        let clampedIndex = max(0, min(index, trendData.count - 1))
        return trendData[clampedIndex]
    }
}

// MARK: - Supporting Views

struct ImprovementIndicator: View {
    let improvement: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: improvement >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(improvement >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            
            Text(String(format: "%.1f%%", abs(improvement)))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(improvement >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(improvement >= 0 ? DesignSystem.Colors.success.opacity(0.1) : DesignSystem.Colors.error.opacity(0.1))
        )
    }
}

struct SelectedDataView: View {
    let data: FillerTrendData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("選択されたデータ")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: 16) {
                DataPoint(title: "日時", value: data.detailedDate, color: DesignSystem.Colors.primary)
                DataPoint(title: "フィラー語数", value: "\(data.fillerCount)回", color: DesignSystem.Colors.secondary)
                DataPoint(title: "フィラー率", value: String(format: "%.1f%%", data.fillerRate), color: DesignSystem.Colors.accent)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.surface.opacity(0.5))
        )
    }
}

struct DataPoint: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
    }
}

struct EmptyChartView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(message)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(height: ChartConfig.chartHeight)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FillerTrendChart(analyses: [])
        .padding()
}