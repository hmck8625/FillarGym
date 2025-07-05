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
            VStack(spacing: 0) {
                // 統計サマリー
                if !audioSessions.isEmpty {
                    StatsSummarySection(
                        totalSessions: totalSessions,
                        totalDuration: totalDuration,
                        averageFillerCount: averageFillerCount
                    )
                }
                
                // 検索とフィルター
                VStack(spacing: 16) {
                    EnhancedSearchBar(text: $searchText)
                    
                    SortOptionsView(selection: $sortOption)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // セッション一覧
                if filteredSessions.isEmpty {
                    EmptyStateView(hasData: !audioSessions.isEmpty)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredSessions.enumerated()), id: \.element.id) { index, session in
                                ModernSessionCard(
                                    session: session,
                                    index: index,
                                    onTap: {
                                        selectedSession = session
                                        showingSessionDetail = true
                                    },
                                    onDelete: {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("録音履歴")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSessionDetail) {
            if let session = selectedSession {
                SessionDetailView(session: session)
                    .environment(\.managedObjectContext, viewContext)
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

// MARK: - Stats Summary Section
struct StatsSummarySection: View {
    let totalSessions: Int
    let totalDuration: Double
    let averageFillerCount: Double
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                SummaryStatCard(
                    value: "\(totalSessions)",
                    label: "セッション",
                    icon: "mic.circle.fill",
                    color: .blue,
                    delay: 0.0
                )
                
                SummaryStatCard(
                    value: String(format: "%.0f分", totalDuration / 60),
                    label: "総録音時間",
                    icon: "clock.fill",
                    color: .green,
                    delay: 0.1
                )
                
                SummaryStatCard(
                    value: String(format: "%.1f", averageFillerCount),
                    label: "平均フィラー",
                    icon: "chart.bar.fill",
                    color: .orange,
                    delay: 0.2
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct SummaryStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let delay: Double
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(appeared ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: appeared)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(delay + 0.1), value: appeared)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(delay + 0.2), value: appeared)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}

// MARK: - Enhanced Search Bar
struct EnhancedSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isEditing ? .blue : .gray)
                    .animation(.easeInOut(duration: 0.2), value: isEditing)
                
                TextField("録音タイトルや文字起こしを検索", text: $text, onEditingChanged: { editing in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = editing
                    }
                })
                .font(.subheadline)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEditing ? Color.blue : Color.gray.opacity(0.3), lineWidth: isEditing ? 2 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isEditing)
            )
        }
    }
}

// MARK: - Sort Options View
struct SortOptionsView: View {
    @Binding var selection: HistoryView.SortOption
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(HistoryView.SortOption.allCases, id: \.self) { option in
                SortOptionButton(
                    option: option,
                    isSelected: selection == option,
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selection = option
                        }
                    }
                )
            }
        }
    }
}

struct SortOptionButton: View {
    let option: HistoryView.SortOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.caption)
                Text(option.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let hasData: Bool
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: hasData ? "magnifyingglass" : "mic.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
                .onAppear {
                    animateIcon = true
                }
            
            VStack(spacing: 8) {
                Text(hasData ? "検索結果がありません" : "録音履歴がありません")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(hasData ? "別のキーワードで検索してみてください" : "ホーム画面から録音を始めましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Modern Session Card
struct ModernSessionCard: View {
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
            VStack(spacing: 16) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title ?? "録音セッション")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(session.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 統計情報
                HStack(spacing: 16) {
                    StatBadge(
                        value: String(format: "%.1f分", session.duration / 60),
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    StatBadge(
                        value: "\(characterCount)文字",
                        icon: "text.alignleft",
                        color: .green
                    )
                    
                    if let analysis = session.analysis {
                        StatBadge(
                            value: "\(analysis.fillerCount)個",
                            icon: "exclamationmark.bubble.fill",
                            color: .red
                        )
                    }
                    
                    Spacer()
                }
                
                // 文字起こしプレビュー
                VStack(alignment: .leading, spacing: 8) {
                    Text("文字起こし")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(transcriptionPreview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 改善インジケーター
                if let analysis = session.analysis,
                   let improvement = calculateImprovement(for: analysis) {
                    HStack {
                        Image(systemName: improvement >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(improvement >= 0 ? .green : .red)
                        
                        Text(improvement >= 0 ? "前回より\(String(format: "%.1f", improvement))%改善" : "前回より\(String(format: "%.1f", abs(improvement)))%増加")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(improvement >= 0 ? .green : .red)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(cardGradient)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(appeared ? 1.0 : 0.9)
        .opacity(appeared ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: appeared)
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
    
    private func calculateImprovement(for analysis: FillerAnalysis) -> Double? {
        // 簡単な改善計算（実際のロジックは別で実装）
        return Double.random(in: -10...15) // デモ用
    }
}

struct StatBadge: View {
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}