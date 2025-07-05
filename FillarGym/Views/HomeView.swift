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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 録音開始ボタン
                Button(action: {
                    showingRecordingView = true
                }) {
                    VStack {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("録音開始")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 200, height: 120)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                
                // 進捗サマリー
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("今週の進捗")
                            .font(.headline)
                        Spacer()
                        Text(progressTracker?.checkGoalAchievement().description ?? "読み込み中...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        ProgressCard(
                            title: "録音回数", 
                            value: "\(progressTracker?.weeklyProgress?.sessionsCount ?? 0)", 
                            icon: "mic"
                        )
                        ProgressCard(
                            title: "連続日数", 
                            value: "\(progressTracker?.streakDays ?? 0)日", 
                            icon: "flame"
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        ProgressCard(
                            title: "週平均フィラー", 
                            value: "\(String(format: "%.1f", progressTracker?.weeklyProgress?.averageFillerRate ?? 0))/分", 
                            icon: "chart.line.downtrend.xyaxis"
                        )
                        ProgressCard(
                            title: "改善率", 
                            value: "\(String(format: "%.1f", progressTracker?.averageImprovement ?? 0))%", 
                            icon: (progressTracker?.averageImprovement ?? 0) >= 0 ? "arrow.up" : "arrow.down"
                        )
                    }
                    .padding(.horizontal)
                }
                
                // 最近の録音履歴
                VStack(alignment: .leading, spacing: 10) {
                    Text("最近の録音")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if recentSessions.isEmpty {
                        Text("まだ録音がありません")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(recentSessions.prefix(3), id: \.id) { session in
                            RecentSessionRow(session: session)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("FillarGym")
        }
        .sheet(isPresented: $showingRecordingView) {
            RecordingView()
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
}

struct ProgressCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct RecentSessionRow: View {
    let session: AudioSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.title ?? "録音セッション")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(session.duration))秒")
                    .font(.caption)
                if let analysis = session.analysis {
                    Text("\(analysis.fillerCount)個")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}