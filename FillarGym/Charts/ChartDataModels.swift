import Foundation
import SwiftUI
import Charts

// MARK: - Chart Data Models

/// フィラー語推移チャート用のデータモデル
struct FillerTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let fillerCount: Int
    let fillerRate: Double
    let speakingSpeed: Double
    
    /// 日付をフォーマットした文字列を返す
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    /// 時間を含む詳細な日付フォーマット
    var detailedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

/// フィラー語種別分布用のデータモデル
struct FillerWordDistribution: Identifiable {
    let id = UUID()
    let word: String
    let count: Int
    let percentage: Double
    
    /// 表示用の文字列
    var displayText: String {
        return "\(word) (\(count)回)"
    }
}

/// エリアチャート用のデータモデル
struct FillerRateAreaData: Identifiable {
    let id = UUID()
    let date: Date
    let fillerRate: Double
    let cumulativeAverage: Double
    
    /// 日付をフォーマットした文字列を返す
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Chart Configuration

/// チャートの設定値
struct ChartConfig {
    static let cornerRadius: CGFloat = 12
    static let chartHeight: CGFloat = 200
    static let animationDuration: Double = 1.0
    
    /// プレミアムブルーのグラデーション
    static func primaryGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.secondary.opacity(0.7),
                DesignSystem.Colors.secondary.opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// セカンダリグラデーション
    static func secondaryGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.primary.opacity(0.7),
                DesignSystem.Colors.primary.opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// アクセントグラデーション
    static func accentGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.accent.opacity(0.7),
                DesignSystem.Colors.accent.opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Data Processing Extensions

extension Array where Element == FillerAnalysis {
    /// フィラー語推移データに変換
    func toTrendData() -> [FillerTrendData] {
        return self.map { analysis in
            FillerTrendData(
                date: analysis.analysisDate ?? Date(),
                fillerCount: Int(analysis.fillerCount),
                fillerRate: analysis.fillerRate,
                speakingSpeed: analysis.speakingSpeed
            )
        }.sorted { $0.date < $1.date }
    }
    
    /// フィラー率エリアデータに変換
    func toAreaData() -> [FillerRateAreaData] {
        let sortedAnalyses = self.sorted { ($0.analysisDate ?? Date()) < ($1.analysisDate ?? Date()) }
        var cumulativeSum: Double = 0
        
        return sortedAnalyses.enumerated().map { index, analysis in
            cumulativeSum += analysis.fillerRate
            let average = cumulativeSum / Double(index + 1)
            
            return FillerRateAreaData(
                date: analysis.analysisDate ?? Date(),
                fillerRate: analysis.fillerRate,
                cumulativeAverage: average
            )
        }
    }
    
    /// フィラー語種別分布データに変換
    func toDistributionData() -> [FillerWordDistribution] {
        var wordCounts: [String: Int] = [:]
        var totalCount = 0
        
        // 全てのフィラー語をカウント
        for analysis in self {
            if let fillerWords = analysis.fillerWords?.allObjects as? [FillerWord] {
                for fillerWord in fillerWords {
                    let word = fillerWord.word ?? "不明"
                    let count = Int(fillerWord.count)
                    wordCounts[word, default: 0] += count
                    totalCount += count
                }
            }
        }
        
        // 分布データに変換
        return wordCounts.map { word, count in
            let percentage = totalCount > 0 ? (Double(count) / Double(totalCount)) * 100 : 0
            return FillerWordDistribution(
                word: word,
                count: count,
                percentage: percentage
            )
        }.sorted { $0.count > $1.count }
    }
}

// MARK: - Color Extension
// Note: Color(hex:) extension is defined in DesignSystem.swift