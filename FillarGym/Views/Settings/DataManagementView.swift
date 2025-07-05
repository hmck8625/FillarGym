import SwiftUI
import CoreData

struct DataManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: AudioSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var audioSessions: FetchedResults<AudioSession>
    
    @State private var showingDeleteAllAlert = false
    @State private var showingExportSheet = false
    @State private var dataSize = "計算中..."
    
    var body: some View {
        List {
            // データ統計
            Section("データ統計") {
                StatRow(title: "総録音数", value: "\(audioSessions.count)回")
                StatRow(title: "総分析数", value: "\(audioSessions.compactMap { $0.analysis }.count)回")
                StatRow(title: "使用容量", value: dataSize)
                StatRow(title: "最古の録音", value: oldestRecordingDate)
                StatRow(title: "最新の録音", value: newestRecordingDate)
            }
            
            // データ操作
            Section("データ操作") {
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("データをエクスポート")
                        Spacer()
                    }
                }
                
                Button(action: {
                    calculateDataSize()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("使用容量を再計算")
                        Spacer()
                    }
                }
                
                Button(action: {
                    showingDeleteAllAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("すべてのデータを削除")
                        Spacer()
                    }
                }
                .foregroundColor(.red)
            }
            
            // プライバシー
            Section("プライバシー") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("データの取り扱いについて")
                        .font(.headline)
                    
                    Text("• 録音データはお使いのデバイス内にのみ保存されます")
                    Text("• 分析のため音声データをOpenAI APIに送信します")
                    Text("• 送信された音声データはOpenAIによって一時的に処理され、保存されません")
                    Text("• 分析結果のみがアプリ内に保存されます")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .navigationTitle("データ管理")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateDataSize()
        }
        .alert("全データ削除", isPresented: $showingDeleteAllAlert) {
            Button("削除", role: .destructive) {
                deleteAllData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この操作は取り消せません。本当にすべての録音データと分析結果を削除しますか？")
        }
        .sheet(isPresented: $showingExportSheet) {
            DataExportView()
        }
    }
    
    private var oldestRecordingDate: String {
        if let oldest = audioSessions.last?.createdAt {
            return DateFormatter.localizedString(from: oldest, dateStyle: .short, timeStyle: .none)
        }
        return "なし"
    }
    
    private var newestRecordingDate: String {
        if let newest = audioSessions.first?.createdAt {
            return DateFormatter.localizedString(from: newest, dateStyle: .short, timeStyle: .none)
        }
        return "なし"
    }
    
    private func calculateDataSize() {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            _ = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            var totalSize: Int64 = 0
            
            for session in audioSessions {
                if let filePath = session.filePath,
                   let fileURL = URL(string: filePath),
                   fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                        if let size = attributes[.size] as? Int64 {
                            totalSize += size
                        }
                    } catch {
                        print("ファイルサイズ取得エラー: \(error)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.dataSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
            }
        }
    }
    
    private func deleteAllData() {
        // 音声ファイルの削除
        for session in audioSessions {
            if let filePath = session.filePath,
               let fileURL = URL(string: filePath) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        
        // Core Dataからの削除
        for session in audioSessions {
            viewContext.delete(session)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("データ削除エラー: \(error)")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: AudioSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AudioSession.createdAt, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var audioSessions: FetchedResults<AudioSession>
    
    @State private var selectedFormat = ExportFormat.json
    @State private var includeAudioFiles = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // エクスポート設定
                VStack(alignment: .leading, spacing: 15) {
                    Text("エクスポート設定")
                        .font(.headline)
                    
                    Picker("フォーマット", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("音声ファイルを含める", isOn: $includeAudioFiles)
                        .toggleStyle(SwitchToggleStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // エクスポート内容
                VStack(alignment: .leading, spacing: 10) {
                    Text("エクスポート内容")
                        .font(.headline)
                    
                    Text("• 録音セッション情報（\(audioSessions.count)件）")
                    Text("• 分析結果データ（\(audioSessions.compactMap { $0.analysis }.count)件）")
                    Text("• フィラー語詳細データ")
                    if includeAudioFiles {
                        Text("• 音声ファイル（容量大）")
                            .foregroundColor(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // エクスポートボタン
                Button(action: {
                    startExport()
                }) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? "エクスポート中..." : "エクスポート開始")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
            }
            .padding()
            .navigationTitle("データエクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheetForFile(url: url)
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        
        DispatchQueue.global(qos: .background).async {
            do {
                let url = try self.createExportFile()
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportURL = url
                    self.showingShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    print("エクスポートエラー: \(error)")
                }
            }
        }
    }
    
    private func createExportFile() throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "FillarGym_Export_\(Date().timeIntervalSince1970).\(selectedFormat.fileExtension)"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        switch selectedFormat {
        case .json:
            let exportData = createJSONExportData()
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            
        case .csv:
            let csvContent = createCSVExportData()
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        return fileURL
    }
    
    private func createJSONExportData() -> [String: Any] {
        var exportData: [String: Any] = [:]
        exportData["export_date"] = ISO8601DateFormatter().string(from: Date())
        exportData["app_version"] = "1.0.0"
        
        var sessionsData: [[String: Any]] = []
        
        for session in audioSessions {
            var sessionData: [String: Any] = [
                "id": session.id?.uuidString ?? "",
                "title": session.title ?? "",
                "created_at": ISO8601DateFormatter().string(from: session.createdAt ?? Date()),
                "duration": session.duration
            ]
            
            if let analysis = session.analysis {
                sessionData["analysis"] = [
                    "filler_count": analysis.fillerCount,
                    "filler_rate": analysis.fillerRate,
                    "speaking_speed": analysis.speakingSpeed,
                    "analysis_date": ISO8601DateFormatter().string(from: analysis.analysisDate ?? Date())
                ]
            }
            
            sessionsData.append(sessionData)
        }
        
        exportData["sessions"] = sessionsData
        return exportData
    }
    
    private func createCSVExportData() -> String {
        var csv = "日付,タイトル,録音時間(秒),フィラー数,フィラー率(/分),発話速度(語/分)\n"
        
        for session in audioSessions {
            let date = session.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let title = session.title ?? ""
            let duration = "\(session.duration)"
            let fillerCount = "\(session.analysis?.fillerCount ?? 0)"
            let fillerRate = String(format: "%.1f", session.analysis?.fillerRate ?? 0)
            let speakingSpeed = String(format: "%.1f", session.analysis?.speakingSpeed ?? 0)
            
            csv += "\(date),\(title),\(duration),\(fillerCount),\(fillerRate),\(speakingSpeed)\n"
        }
        
        return csv
    }
}

struct ShareSheetForFile: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}