import Foundation
import CoreData
import Combine

class ProgressTracker: ObservableObject {
    @Published var weeklyProgress: WeeklyProgress?
    @Published var monthlyProgress: MonthlyProgress?
    @Published var streakDays: Int = 0
    @Published var totalSessions: Int = 0
    @Published var averageImprovement: Double = 0.0
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        calculateProgress()
    }
    
    func calculateProgress() {
        calculateWeeklyProgress()
        calculateMonthlyProgress()
        calculateStreakDays()
        calculateOverallStats()
    }
    
    private func calculateWeeklyProgress() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let request: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", weekStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: true)]
        
        do {
            let sessions = try viewContext.fetch(request)
            weeklyProgress = WeeklyProgress(
                sessionsCount: sessions.count,
                totalFillerWords: sessions.compactMap { Int($0.analysis?.fillerCount ?? 0) }.reduce(0, +),
                averageFillerRate: calculateAverageFillerRate(from: sessions),
                dailyBreakdown: createDailyBreakdown(sessions: sessions, startDate: weekStart)
            )
        } catch {
            print("週間進捗計算エラー: \(error)")
        }
    }
    
    private func calculateMonthlyProgress() {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let request: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", monthStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: true)]
        
        do {
            let sessions = try viewContext.fetch(request)
            monthlyProgress = MonthlyProgress(
                sessionsCount: sessions.count,
                totalFillerWords: sessions.compactMap { Int($0.analysis?.fillerCount ?? 0) }.reduce(0, +),
                averageFillerRate: calculateAverageFillerRate(from: sessions),
                weeklyBreakdown: createWeeklyBreakdown(sessions: sessions, startDate: monthStart)
            )
        } catch {
            print("月間進捗計算エラー: \(error)")
        }
    }
    
    private func calculateStreakDays() {
        let calendar = Calendar.current
        let now = Date()
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: now)
        
        while true {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            
            let request: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
            request.predicate = NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@",
                checkDate as NSDate,
                nextDate as NSDate
            )
            
            do {
                let count = try viewContext.count(for: request)
                if count > 0 {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else {
                    break
                }
            } catch {
                break
            }
        }
        
        streakDays = currentStreak
    }
    
    private func calculateOverallStats() {
        let request: NSFetchRequest<AudioSession> = AudioSession.fetchRequest()
        
        do {
            totalSessions = try viewContext.count(for: request)
            
            // 改善率の計算
            let analysisRequest: NSFetchRequest<FillerAnalysis> = FillerAnalysis.fetchRequest()
            analysisRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FillerAnalysis.analysisDate, ascending: true)]
            
            let analyses = try viewContext.fetch(analysisRequest)
            if analyses.count >= 2 {
                let improvements = zip(analyses.dropFirst(), analyses).map { current, previous in
                    current.calculateImprovement(from: previous)
                }
                averageImprovement = improvements.reduce(0, +) / Double(improvements.count)
            }
        } catch {
            print("全体統計計算エラー: \(error)")
        }
    }
    
    private func calculateAverageFillerRate(from sessions: [AudioSession]) -> Double {
        let rates = sessions.compactMap { $0.analysis?.fillerRate }
        guard !rates.isEmpty else { return 0.0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
    
    private func createDailyBreakdown(sessions: [AudioSession], startDate: Date) -> [DailyData] {
        let calendar = Calendar.current
        var dailyData: [DailyData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            let sessionsForDay = sessions.filter {
                calendar.isDate($0.createdAt ?? Date(), inSameDayAs: date)
            }
            
            dailyData.append(DailyData(
                date: date,
                sessionCount: sessionsForDay.count,
                fillerCount: sessionsForDay.compactMap { Int($0.analysis?.fillerCount ?? 0) }.reduce(0, +)
            ))
        }
        
        return dailyData
    }
    
    private func createWeeklyBreakdown(sessions: [AudioSession], startDate: Date) -> [WeeklyData] {
        let calendar = Calendar.current
        var weeklyData: [WeeklyData] = []
        
        for i in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: i, to: startDate) ?? startDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            
            let sessionsForWeek = sessions.filter {
                guard let createdAt = $0.createdAt else { return false }
                return createdAt >= weekStart && createdAt < weekEnd
            }
            
            weeklyData.append(WeeklyData(
                weekStart: weekStart,
                sessionCount: sessionsForWeek.count,
                fillerCount: sessionsForWeek.compactMap { Int($0.analysis?.fillerCount ?? 0) }.reduce(0, +)
            ))
        }
        
        return weeklyData
    }
    
    // MARK: - Goal Management
    func checkGoalAchievement() -> GoalStatus {
        guard let settings = getUserSettings(),
              let _ = weeklyProgress else {
            return .noGoal
        }
        
        let monthlyGoal = Int(settings.monthlyGoal)
        let currentMonthSessions = monthlyProgress?.sessionsCount ?? 0
        
        if currentMonthSessions >= monthlyGoal {
            return .achieved
        } else {
            let progress = Double(currentMonthSessions) / Double(monthlyGoal)
            return .inProgress(progress)
        }
    }
    
    private func getUserSettings() -> UserSettings? {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        return try? viewContext.fetch(request).first
    }
}

// MARK: - Data Models
struct WeeklyProgress {
    let sessionsCount: Int
    let totalFillerWords: Int
    let averageFillerRate: Double
    let dailyBreakdown: [DailyData]
}

struct MonthlyProgress {
    let sessionsCount: Int
    let totalFillerWords: Int
    let averageFillerRate: Double
    let weeklyBreakdown: [WeeklyData]
}

struct DailyData {
    let date: Date
    let sessionCount: Int
    let fillerCount: Int
}

struct WeeklyData {
    let weekStart: Date
    let sessionCount: Int
    let fillerCount: Int
}

enum GoalStatus {
    case noGoal
    case achieved
    case inProgress(Double)
    
    var description: String {
        switch self {
        case .noGoal:
            return "目標が設定されていません"
        case .achieved:
            return "目標達成！🎉"
        case .inProgress(let progress):
            return "進捗: \(Int(progress * 100))%"
        }
    }
}