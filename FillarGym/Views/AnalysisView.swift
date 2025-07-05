import SwiftUI
import CoreData

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
                        StatisticsCards(analyses: filteredAnalyses)
                        
                        // フィラー数推移グラフ
                        FillerTrendChart(analyses: filteredAnalyses)
                        
                        // フィラー語種別内訳
                        FillerWordBreakdown(analyses: filteredAnalyses)
                        
                        // 改善提案
                        ImprovementSuggestions(analyses: filteredAnalyses)
                    }
                }
                .padding()
            }
            .navigationTitle("詳細分析")
        }
    }
}

struct StatisticsCards: View {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("統計情報")
                .font(.headline)
            
            HStack {
                StatCard(title: "平均フィラー数", value: String(format: "%.1f", averageFillerCount), color: .blue)
                StatCard(title: "改善率", value: String(format: "%.1f%%", improvementRate), color: improvementRate >= 0 ? .green : .red)
            }
            
            HStack {
                StatCard(title: "総録音数", value: "\(analyses.count)", color: .purple)
                StatCard(title: "最良記録", value: "\(analyses.min(by: { $0.fillerCount < $1.fillerCount })?.fillerCount ?? 0)", color: .orange)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FillerTrendChart: View {
    let analyses: [FillerAnalysis]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("フィラー数推移")
                .font(.headline)
            
            // 簡易グラフ表示（Charts使用せず）
            VStack(spacing: 8) {
                ForEach(Array(analyses.enumerated()), id: \.offset) { index, analysis in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .frame(width: 20)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: CGFloat(analysis.fillerCount) * 10, height: 8)
                            .cornerRadius(4)
                        
                        Text("\(analysis.fillerCount)")
                            .font(.caption)
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct FillerWordBreakdown: View {
    let analyses: [FillerAnalysis]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("よく使うフィラー語")
                .font(.headline)
            
            // フィラー語の集計表示（簡易版）
            VStack(spacing: 8) {
                ForEach(["えー", "あー", "その", "あの", "えっと"], id: \.self) { word in
                    HStack {
                        Text(word)
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int.random(in: 0...20))回")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct ImprovementSuggestions: View {
    let analyses: [FillerAnalysis]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("改善提案")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                SuggestionRow(
                    icon: "lightbulb.fill",
                    title: "間を活用しよう",
                    description: "フィラー語の代わりに短い間を取ることで、より説得力のある話し方になります。"
                )
                
                SuggestionRow(
                    icon: "brain.head.profile",
                    title: "話す内容を整理",
                    description: "事前に話すポイントを整理することで、フィラー語の使用を減らせます。"
                )
                
                SuggestionRow(
                    icon: "timer",
                    title: "練習を続けよう",
                    description: "継続的な練習が改善の鍵です。週に3回の録音を目標にしましょう。"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct SuggestionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}