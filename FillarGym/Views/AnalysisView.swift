import SwiftUI
import CoreData
import Charts

struct AnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: FillerAnalysis.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FillerAnalysis.analysisDate, ascending: true)],
        predicate: nil,
        animation: .default
    ) private var analyses: FetchedResults<FillerAnalysis>
    
    @State private var selectedPeriod = TimePeriod.week
    
    enum TimePeriod: String, CaseIterable {
        case week = "週"
        case month = "月"
        case year = "年"
    }
    
    var filteredAnalyses: [FillerAnalysis] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return analyses.filter { analysis in
            (analysis.analysisDate ?? Date()) >= startDate
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if filteredAnalyses.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("分析データがありません")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("録音を行って分析を開始しましょう")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        // 統計カード
                        ModernStatisticsCards(analyses: filteredAnalyses)
                        
                        // フィラー語推移チャート（新しい線グラフ）
                        FillerTrendChart(analyses: filteredAnalyses)
                        
                        // フィラー率エリアチャート（新機能）
                        FillerRateAreaChart(analyses: filteredAnalyses)
                        
                        // フィラー語種別円グラフ（新機能）
                        FillerWordPieChart(analyses: filteredAnalyses)
                        
                        // 改善提案
                        ModernImprovementSuggestions(analyses: filteredAnalyses)
                    }
                }
                .padding()
            }
            .navigationTitle("詳細分析")
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.surfaceElevated,
                        DesignSystem.Colors.surface
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Legacy components removed
// These have been replaced with modern chart components in separate files:
// - ModernStatisticsCards in ModernAnalysisComponents.swift
// - FillerTrendChart in FillerTrendChart.swift  
// - FillerRateAreaChart in FillerRateAreaChart.swift
// - FillerWordPieChart in FillerWordPieChart.swift
// - ModernImprovementSuggestions in ModernAnalysisComponents.swift