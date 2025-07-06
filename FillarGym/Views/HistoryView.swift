import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: AudioSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var audioSessions: FetchedResults<AudioSession>
    
    @State private var searchText = ""
    @State private var sortOption = SortOption.date
    @State private var selectedSession: AudioSession?
    @State private var showingSessionDetail = false
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: AudioSession?
    
    enum SortOption: String, CaseIterable {
        case date = "日付"
        case fillerCount = "フィラー数"
        case duration = "録音時間"
        
        var icon: String {
            switch self {
            case .date: return "calendar"
            case .fillerCount: return "exclamationmark.bubble"
            case .duration: return "clock"
            }
        }
    }
    
    var filteredSessions: [AudioSession] {
        let filtered = audioSessions.filter { session in
            if searchText.isEmpty {
                return true
            }
            
            let titleMatch = session.title?.lowercased().contains(searchText.lowercased()) ?? false
            let transcriptionMatch = session.transcription?.lowercased().contains(searchText.lowercased()) ?? false
            
            return titleMatch || transcriptionMatch
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .date:
                return (first.createdAt ?? Date()) > (second.createdAt ?? Date())
            case .fillerCount:
                return (first.analysis?.fillerCount ?? 0) > (second.analysis?.fillerCount ?? 0)
            case .duration:
                return first.duration > second.duration
            }
        }
    }
    
    private var totalSessions: Int { audioSessions.count }
    private var totalDuration: Double { audioSessions.reduce(0) { $0 + $1.duration } }
    private var averageFillerCount: Double {
        let analysisCount = audioSessions.compactMap { $0.analysis }.count
        guard analysisCount > 0 else { return 0 }
        let totalFillerCount = audioSessions.compactMap { $0.analysis?.fillerCount }.reduce(0, +)
        return Double(totalFillerCount) / Double(analysisCount)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // 統計サマリー
                    if !audioSessions.isEmpty {
                        ModernStatsSummarySection(
                            totalSessions: totalSessions,
                            totalDuration: totalDuration,
                            averageFillerCount: averageFillerCount
                        )
                    }
                    
                    // 検索とフィルター
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ModernSearchBar(text: $searchText)
                        ModernSortOptionsView(selection: $sortOption)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // セッション一覧
                    if filteredSessions.isEmpty {
                        ModernEmptyStateView(hasData: !audioSessions.isEmpty)
                    } else {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(Array(filteredSessions.enumerated()), id: \.element.id) { index, session in
                                ModernHistorySessionCard(
                                    session: session,
                                    index: index,
                                    onTap: {
                                        print("=== HistoryView: Session Card Tapped ===")
                                        print("📊 Session ID: \(session.id?.uuidString ?? "nil")")
                                        print("📊 Session Title: \(session.title ?? "nil")")
                                        print("📊 Session isDeleted: \(session.isDeleted)")
                                        print("📊 Session managedObjectContext: \(session.managedObjectContext != nil)")
                                        print("📊 Session transcription length: \(session.transcription?.count ?? 0)")
                                        print("📊 Session has analysis: \(session.analysis != nil)")
                                        if let analysis = session.analysis {
                                            print("📊 Analysis ID: \(analysis.id?.uuidString ?? "nil")")
                                            print("📊 Analysis filler count: \(analysis.fillerCount)")
                                        }
                                        print("📊 Setting selectedSession and showing detail...")
                                        
                                        selectedSession = session
                                        showingSessionDetail = true
                                        
                                        print("📊 selectedSession set: \(selectedSession?.id?.uuidString ?? "nil")")
                                        print("📊 showingSessionDetail: \(showingSessionDetail)")
                                        print("=== End HistoryView Session Tap ===\n")
                                    },
                                    onDelete: {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
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
            .navigationTitle("録音履歴")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
                .environment(\.managedObjectContext, viewContext)
                .onAppear {
                    print("=== HistoryView: Sheet Presentation ===")
                    print("📋 Sheet presented with session: \(session.id?.uuidString ?? "nil")")
                    print("📋 Session context: \(session.managedObjectContext != nil)")
                    print("📋 ViewContext: \(viewContext)")
                    print("📋 SessionDetailView sheet appeared")
                }
        }
        .alert("セッションを削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この録音セッションを完全に削除しますか？この操作は取り消せません。")
        }
        .onAppear {
            print("=== HistoryView onAppear ===")
            print("📊 Total sessions: \(audioSessions.count)")
            print("📊 Filtered sessions: \(filteredSessions.count)")
            for (index, session) in audioSessions.enumerated().prefix(5) {
                print("📊 Session[\(index)]: \(session.id?.uuidString ?? "nil") - \(session.title ?? "nil")")
                print("   - Has analysis: \(session.analysis != nil)")
                print("   - Context: \(session.managedObjectContext != nil)")
            }
            print("=== End HistoryView onAppear ===\n")
        }
    }
    
    private func deleteSession(_ session: AudioSession) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewContext.delete(session)
            
            do {
                try viewContext.save()
            } catch {
                print("削除エラー: \(error)")
            }
        }
    }
}

// MARK: - Modern Stats Summary Section
struct ModernStatsSummarySection: View {
    let totalSessions: Int
    let totalDuration: Double
    let averageFillerCount: Double
    @State private var appeared = false
    
    var body: some View {
        ModernCard(elevation: .medium, padding: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                HStack {
                    Text("録音統計")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 3), spacing: DesignSystem.Spacing.md) {
                    ModernSummaryStatCard(
                        value: "\(totalSessions)",
                        label: "セッション",
                        icon: "mic.circle.fill",
                        color: DesignSystem.Colors.primary,
                        delay: 0.0
                    )
                    
                    ModernSummaryStatCard(
                        value: String(format: "%.0f分", totalDuration / 60),
                        label: "総録音時間",
                        icon: "clock.fill",
                        color: DesignSystem.Colors.success,
                        delay: 0.1
                    )
                    
                    ModernSummaryStatCard(
                        value: String(format: "%.1f", averageFillerCount),
                        label: "平均フィラー",
                        icon: "chart.bar.fill",
                        color: DesignSystem.Colors.warning,
                        delay: 0.2
                    )
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct ModernSummaryStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let delay: Double
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.large, weight: .semibold))
                .foregroundColor(color)
                .scaleEffect(appeared ? 1.0 : 0.5)
                .animation(DesignSystem.Animation.springBouncy.delay(delay), value: appeared)
            
            Text(value)
                .font(DesignSystem.Typography.numberMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(DesignSystem.Animation.standard.delay(delay + 0.1), value: appeared)
            
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(DesignSystem.Animation.standard.delay(delay + 0.2), value: appeared)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

// MARK: - Modern Search Bar
struct ModernSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: DesignSystem.IconSize.medium, weight: .medium))
                    .foregroundColor(isEditing ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                    .animation(DesignSystem.Animation.quick, value: isEditing)
                
                TextField("録音タイトルや文字起こしを検索", text: $text, onEditingChanged: { editing in
                    withAnimation(DesignSystem.Animation.quick) {
                        isEditing = editing
                    }
                })
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(DesignSystem.Animation.quick) {
                            text = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.medium, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(isEditing ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                .animation(DesignSystem.Animation.quick, value: isEditing)
        )
    }
}

// MARK: - Modern Sort Options View
struct ModernSortOptionsView: View {
    @Binding var selection: HistoryView.SortOption
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(HistoryView.SortOption.allCases, id: \.self) { option in
                ModernSortOptionButton(
                    option: option,
                    isSelected: selection == option,
                    action: {
                        withAnimation(DesignSystem.Animation.quick) {
                            selection = option
                        }
                    }
                )
            }
        }
    }
}

struct ModernSortOptionButton: View {
    let option: HistoryView.SortOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: option.icon)
                    .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                Text(option.rawValue)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.textInverse : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                    .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
        .pressAnimation()
    }
}

// MARK: - Modern Empty State View
struct ModernEmptyStateView: View {
    let hasData: Bool
    @State private var animateIcon = false
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.xl) {
            VStack(spacing: DesignSystem.Spacing.xl) {
                Image(systemName: hasData ? "magnifyingglass" : "mic.slash")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                    .onAppear {
                        animateIcon = true
                    }
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(hasData ? "検索結果がありません" : "録音履歴がありません")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(hasData ? "別のキーワードで検索してみてください" : "ホーム画面から録音を始めましょう")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern History Session Card
struct ModernHistorySessionCard: View {
    let session: AudioSession
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var appeared = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var transcriptionPreview: String {
        guard let transcription = session.transcription, !transcription.isEmpty else {
            return "文字起こしデータがありません"
        }
        return String(transcription.prefix(80)) + (transcription.count > 80 ? "..." : "")
    }
    
    private var characterCount: Int {
        session.transcription?.count ?? 0
    }
    
    private var cardGradient: LinearGradient {
        let colors = [
            Color.blue.opacity(0.1),
            Color.purple.opacity(0.05),
            Color(.systemBackground)
        ]
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Button(action: onTap) {
            ModernCard(elevation: .medium, padding: DesignSystem.Spacing.lg) {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // ヘッダー
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(session.title ?? "録音セッション")
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                            
                            Text(session.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: DesignSystem.IconSize.medium, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 統計情報
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ModernStatBadge(
                            value: String(format: "%.1f分", session.duration / 60),
                            icon: "clock.fill",
                            color: DesignSystem.Colors.primary
                        )
                        
                        ModernStatBadge(
                            value: "\(characterCount)文字",
                            icon: "text.alignleft",
                            color: DesignSystem.Colors.success
                        )
                        
                        if let analysis = session.analysis {
                            ModernStatBadge(
                                value: "\(analysis.fillerCount)個",
                                icon: "exclamationmark.bubble.fill",
                                color: DesignSystem.Colors.error
                            )
                        }
                        
                        Spacer()
                    }
                    
                    // 文字起こしプレビュー
                    ModernCard(elevation: .low, padding: DesignSystem.Spacing.md) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("文字起こし")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(transcriptionPreview)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                }
            }
        }
        .buttonStyle(.plain)
        .pressAnimation()
        .scaleEffect(appeared ? 1.0 : 0.9)
        .opacity(appeared ? 1.0 : 0.0)
        .animation(DesignSystem.Animation.standard.delay(Double(index) * 0.1), value: appeared)
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

struct ModernStatBadge: View {
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(DesignSystem.Typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}