import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: AudioSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var recentSessions: FetchedResults<AudioSession>
    
    @State private var progressTracker: ProgressTracker?
    @State private var showingRecordingView = false
    @State private var selectedSession: AudioSession?
    @State private var showingSessionDetail = false
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // Header Section
                    headerSection
                    
                    // Main Recording Button
                    mainRecordingButton
                    
                    // Progress Summary Cards
                    progressSummarySection
                    
                    // Recent Sessions
                    recentSessionsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.background,
                        DesignSystem.Colors.surfaceElevated.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("FillarGym")
            .toolbarBackground(
                DesignSystem.Colors.surface.opacity(0.9),
                for: .navigationBar
            )
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showingRecordingView) {
            RecordingView()
        }
        .sheet(isPresented: $showingSessionDetail) {
            if let session = selectedSession {
                SessionDetailView(session: session)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            if progressTracker == nil {
                progressTracker = ProgressTracker(viewContext: viewContext)
            }
            progressTracker?.calculateProgress()
        }
        .onChange(of: recentSessions.count) {
            progressTracker?.calculateProgress()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("おかえりなさい！")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.light)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("今日も話し方の改善を始めましょう")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Achievement badge if goals met
            if let tracker = progressTracker {
                let goalStatus = tracker.checkGoalAchievement()
                switch goalStatus {
                case .noGoal:
                    EmptyView()
                case .achieved:
                    StatusBadge(
                        text: goalStatus.description,
                        status: .success
                    )
                case .inProgress(_):
                    StatusBadge(
                        text: goalStatus.description,
                        status: .info
                    )
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
    }
    
    // MARK: - Main Recording Button
    private var mainRecordingButton: some View {
        Button(action: {
            showingRecordingView = true
        }) {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // 上部に適切なスペースを追加
                Spacer()
                    .frame(height: DesignSystem.Spacing.lg)
                
                // Premium Icon with Enhanced Glow Effect - 中央寄せ
                ZStack {
                    // 外側のグロー効果
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.15),
                                    Color.blue.opacity(0.08),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 6)
                    
                    // メインの背景サークル
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.2),
                                    Color.blue.opacity(0.1),
                                    DesignSystem.Colors.surfaceElevated
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3),
                                            Color.blue.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: Color.blue.opacity(0.2),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    // マイクアイコン
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: DesignSystem.Colors.shadowMedium,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                }
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("録音を開始")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .shadow(
                            color: DesignSystem.Colors.shadowLight,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    
                    Text("プロフェッショナルな話し方の分析を始めましょう")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Premium Gradient Button with Icon
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("録音開始")
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.ButtonSize.large)
                .background(
                    ZStack {
                        // ベースのグラデーション（青系で緩やか）
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // 立体感のためのハイライト
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear,
                                Color.black.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                )
                .cornerRadius(DesignSystem.CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.blue.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .shadow(
                    color: DesignSystem.Colors.shadowMedium,
                    radius: 3,
                    x: 0,
                    y: 1
                )
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // 下部に適切なスペースを追加してバランスを整える
                Spacer()
                    .frame(height: DesignSystem.Spacing.md)
            }
        }
        .buttonStyle(.plain)
        .pressAnimation()
        .background(
            ModernCard(elevation: .high, isPremium: true) {
                Color.clear
            }
        )
    }
    
    // MARK: - Progress Summary Section
    private var progressSummarySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("今週の進捗")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2), spacing: DesignSystem.Spacing.md) {
                ModernMetricCard(
                    title: "録音回数",
                    value: "\(progressTracker?.weeklyProgress?.sessionsCount ?? 0)",
                    subtitle: "今週",
                    color: DesignSystem.Colors.primary,
                    icon: "mic.fill"
                )
                
                ModernMetricCard(
                    title: "連続日数",
                    value: "\(progressTracker?.streakDays ?? 0)",
                    subtitle: "日間",
                    color: DesignSystem.Colors.secondary,
                    icon: "flame.fill",
                    trend: getTrend(for: progressTracker?.streakDays ?? 0)
                )
                
                ModernMetricCard(
                    title: "平均フィラー率",
                    value: String(format: "%.1f", progressTracker?.weeklyProgress?.averageFillerRate ?? 0),
                    subtitle: "回/分",
                    color: DesignSystem.Colors.accent,
                    icon: "chart.line.downtrend.xyaxis"
                )
                
                ModernMetricCard(
                    title: "改善率",
                    value: "\(String(format: "%.1f", progressTracker?.averageImprovement ?? 0))%",
                    subtitle: "前週比",
                    color: (progressTracker?.averageImprovement ?? 0) >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error,
                    icon: (progressTracker?.averageImprovement ?? 0) >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    trend: getTrendForImprovement(progressTracker?.averageImprovement ?? 0)
                )
            }
        }
    }
    
    // MARK: - Recent Sessions Section
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("最近の録音")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if !recentSessions.isEmpty {
                    Button("すべて見る") {
                        selectedTab = 1 // 履歴タブに移動
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            
            if recentSessions.isEmpty {
                ModernCard(elevation: .low) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "mic.slash.circle")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text("まだ録音がありません")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("最初の録音を始めて、話し方の改善を始めましょう")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            } else {
                ForEach(recentSessions.prefix(3), id: \.id) { session in
                    Button(action: {
                        selectedSession = session
                        showingSessionDetail = true
                    }) {
                        ModernRecentSessionRow(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getTrend(for value: Int) -> TrendDirection? {
        if value > 3 { return .up }
        if value == 0 { return .stable }
        return nil
    }
    
    private func getTrendForImprovement(_ improvement: Double) -> TrendDirection? {
        if improvement > 0 { return .up }
        if improvement < 0 { return .down }
        return .stable
    }
}

// MARK: - Modern Metric Card Component
struct ModernMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let icon: String
    let trend: TrendDirection?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        color: Color,
        icon: String,
        trend: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
        self.trend = trend
    }
    
    var body: some View {
        ModernCard(elevation: .medium, padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let trend = trend {
                        TrendIndicator(direction: trend)
                    }
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(value)
                        .font(DesignSystem.Typography.numberMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Modern Recent Session Row
struct ModernRecentSessionRow: View {
    let session: AudioSession
    
    private var sessionTitle: String {
        session.title ?? "録音セッション"
    }
    
    private var formattedDate: String {
        session.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
    }
    
    private var duration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return minutes > 0 ? "\(minutes)分\(seconds)秒" : "\(seconds)秒"
    }
    
    private var fillerInfo: (count: Int, rate: Double)? {
        guard let analysis = session.analysis else { return nil }
        let rate = session.duration > 0 ? Double(analysis.fillerCount) / (session.duration / 60) : 0
        return (count: Int(analysis.fillerCount), rate: rate)
    }
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Session Icon
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: DesignSystem.IconSize.large, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                // Session Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(sessionTitle)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(formattedDate)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // Duration badge
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .medium))
                            Text(duration)
                                .font(DesignSystem.Typography.caption2)
                        }
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        // Filler count badge
                        if let filler = fillerInfo {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(filler.count)個")
                                    .font(DesignSystem.Typography.caption2)
                            }
                            .foregroundColor(getFillerColor(count: filler.count))
                        }
                    }
                }
                
                Spacer()
                
                // Action indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .pressAnimation()
    }
    
    private func getFillerColor(count: Int) -> Color {
        switch count {
        case 0...2: return DesignSystem.Colors.success
        case 3...5: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }
}