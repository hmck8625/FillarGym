import SwiftUI
import Charts

/// フィラー率の改善傾向を表示するエリアチャートコンポーネント
struct FillerRateAreaChart: View {
    let analyses: [FillerAnalysis]
    @State private var animateChart = false
    @State private var selectedData: FillerRateAreaData?
    @State private var showAverage = true
    
    private var areaData: [FillerRateAreaData] {
        analyses.toAreaData()
    }
    
    private var maxFillerRate: Double {
        areaData.map { max($0.fillerRate, $0.cumulativeAverage) }.max() ?? 10.0
    }
    
    var body: some View {
        ModernCard(elevation: .medium, isPremium: true) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("フィラー率推移")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("改善傾向の可視化")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // 平均線表示切り替え
                    Toggle("", isOn: $showAverage)
                        .toggleStyle(ModernToggleStyle())
                        .scaleEffect(0.8)
                }
                
                // 凡例
                LegendView(showAverage: showAverage)
                
                // チャートコンテンツ
                if areaData.isEmpty {
                    EmptyChartView(
                        icon: "chart.line.downtrend.xyaxis",
                        title: "データがありません",
                        message: "録音を行うとフィラー率の推移が表示されます"
                    )
                } else {
                    // 選択されたデータの詳細表示
                    if let selectedData = selectedData {
                        SelectedRateDataView(data: selectedData)
                    }
                    
                    // メインチャート
                    Chart {
                        ForEach(areaData) { data in
                            // フィラー率エリア
                            AreaMark(
                                x: .value("日付", data.date),
                                y: .value("フィラー率", animateChart ? data.fillerRate : 0)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignSystem.Colors.secondary.opacity(0.6),
                                        DesignSystem.Colors.secondary.opacity(0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            // フィラー率ライン
                            LineMark(
                                x: .value("日付", data.date),
                                y: .value("フィラー率", animateChart ? data.fillerRate : 0)
                            )
                            .foregroundStyle(DesignSystem.Colors.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .interpolationMethod(.catmullRom)
                            
                            // 累積平均線（オプション）
                            if showAverage {
                                LineMark(
                                    x: .value("日付", data.date),
                                    y: .value("累積平均", animateChart ? data.cumulativeAverage : 0)
                                )
                                .foregroundStyle(DesignSystem.Colors.accent)
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 4]))
                                .interpolationMethod(.linear)
                            }
                            
                            // データポイント
                            PointMark(
                                x: .value("日付", data.date),
                                y: .value("フィラー率", animateChart ? data.fillerRate : 0)
                            )
                            .foregroundStyle(DesignSystem.Colors.secondary)
                            .symbolSize(selectedData?.id == data.id ? 80 : 40)
                            .opacity(selectedData?.id == data.id ? 1.0 : 0.8)
                            
                            // 選択時のハイライト
                            if let selectedData = selectedData, selectedData.id == data.id {
                                RuleMark(x: .value("日付", data.date))
                                    .foregroundStyle(DesignSystem.Colors.primary.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .annotation(position: .top) {
                                        AnnotationBubble(data: data)
                                    }
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
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text("\(String(format: "%.1f", doubleValue))%")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .chartBackground { _ in
                        Rectangle()
                            .fill(DesignSystem.Colors.surface.opacity(0.1))
                    }
                    .onTapGesture { location in
                        // 簡易的なタップ処理
                        handleSimpleTap(location: location)
                    }
                }
                
                // 改善アドバイス
                if !areaData.isEmpty {
                    ImprovementAdvice(data: areaData)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: ChartConfig.animationDuration).delay(0.2)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleSimpleTap(location: CGPoint) {
        // 簡易的なタップ処理 - ランダムなデータを選択
        if !areaData.isEmpty {
            let randomIndex = Int.random(in: 0..<areaData.count)
            let randomData = areaData[randomIndex]
            
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedData = selectedData?.id == randomData.id ? nil : randomData
            }
        }
    }
    
    private func findNearestData(relativePosition: Double) -> FillerRateAreaData? {
        guard !areaData.isEmpty else { return nil }
        
        let index = Int(relativePosition * Double(areaData.count))
        let clampedIndex = max(0, min(index, areaData.count - 1))
        return areaData[clampedIndex]
    }
}

// MARK: - Supporting Views

struct LegendView: View {
    let showAverage: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            LegendItem(
                color: DesignSystem.Colors.secondary,
                label: "フィラー率",
                style: .solid
            )
            
            if showAverage {
                LegendItem(
                    color: DesignSystem.Colors.accent,
                    label: "累積平均",
                    style: .dashed
                )
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let style: LineStyle
    
    enum LineStyle {
        case solid, dashed
    }
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 16, height: 2)
                .overlay(
                    style == .dashed ?
                    Rectangle()
                        .fill(color)
                        .mask(
                            HStack(spacing: 2) {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .frame(width: 3, height: 2)
                                }
                            }
                        ) : nil
                )
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct SelectedRateDataView: View {
    let data: FillerRateAreaData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("詳細データ")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: 16) {
                DataPoint(
                    title: "日時",
                    value: data.formattedDate,
                    color: DesignSystem.Colors.primary
                )
                DataPoint(
                    title: "フィラー率",
                    value: String(format: "%.1f%%", data.fillerRate),
                    color: DesignSystem.Colors.secondary
                )
                DataPoint(
                    title: "累積平均",
                    value: String(format: "%.1f%%", data.cumulativeAverage),
                    color: DesignSystem.Colors.accent
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignSystem.Colors.surface.opacity(0.8),
                            DesignSystem.Colors.surface.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct AnnotationBubble: View {
    let data: FillerRateAreaData
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(String(format: "%.1f%%", data.fillerRate))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(data.formattedDate)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DesignSystem.Colors.surface)
                .shadow(color: DesignSystem.Colors.shadowLight, radius: 4, x: 0, y: 2)
        )
    }
}

struct ImprovementAdvice: View {
    let data: [FillerRateAreaData]
    
    private var trend: TrendDirection {
        guard data.count >= 2 else { return .stable }
        
        let recent = data.suffix(3).map { $0.fillerRate }.reduce(0, +) / Double(data.suffix(3).count)
        let older = data.prefix(3).map { $0.fillerRate }.reduce(0, +) / Double(data.prefix(3).count)
        
        let difference = recent - older
        
        if difference < -1.0 {
            return .improving
        } else if difference > 1.0 {
            return .declining
        } else {
            return .stable
        }
    }
    
    enum TrendDirection {
        case improving, declining, stable
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: trendIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(trendColor)
            
            Text(trendMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(trendColor.opacity(0.1))
        )
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving:
            return "arrow.down.circle.fill"
        case .declining:
            return "arrow.up.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving:
            return DesignSystem.Colors.success
        case .declining:
            return DesignSystem.Colors.error
        case .stable:
            return DesignSystem.Colors.warning
        }
    }
    
    private var trendMessage: String {
        switch trend {
        case .improving:
            return "フィラー率が改善傾向にあります！この調子で続けましょう。"
        case .declining:
            return "フィラー率が上昇しています。練習頻度を見直してみましょう。"
        case .stable:
            return "フィラー率は安定しています。継続して練習を続けましょう。"
        }
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Text("平均線")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary.opacity(0.3))
                .frame(width: 40, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: configuration.isOn ? 8 : -8)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

#Preview {
    FillerRateAreaChart(analyses: [])
        .padding()
}