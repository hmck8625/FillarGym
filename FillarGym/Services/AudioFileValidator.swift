import Foundation
import AVFoundation

class AudioFileValidator {
    static let shared = AudioFileValidator()
    
    private init() {}
    
    // サポートされる音声フォーマット
    static let supportedFormats = ["m4a", "wav", "mp3", "aac", "mp4"]
    
    func validateAudioFile(at url: URL) async -> ValidationResult {
        print("🔍 音声ファイル検証開始: \(url)")
        
        // セキュリティスコープアクセス開始
        let accessSucceeded = url.startAccessingSecurityScopedResource()
        defer {
            if accessSucceeded {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // ファイル存在確認
        let fileExists = FileManager.default.fileExists(atPath: url.path)
        print("- ファイル存在確認: \(fileExists)")
        guard fileExists else {
            return .failure("ファイルが見つかりません")
        }
        
        // 拡張子チェック
        let fileExtension = url.pathExtension.lowercased()
        guard Self.supportedFormats.contains(fileExtension) else {
            return .failure("サポートされていないファイル形式です。対応形式: \(Self.supportedFormats.joined(separator: ", "))")
        }
        
        // ファイルサイズチェック（最大50MB）
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let maxSize: Int64 = 50 * 1024 * 1024 // 50MB
                if fileSize > maxSize {
                    return .failure("ファイルサイズが大きすぎます（最大50MB）")
                }
            }
        } catch {
            return .failure("ファイル情報の取得に失敗しました")
        }
        
        // AVURLAssetで音声ファイルの詳細情報を取得（iOS 18.0対応）
        let asset = AVURLAsset(url: url)
        
        do {
            // 再生可能かチェック（非同期API使用）
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else {
                return .failure("このファイルは再生できません")
            }
            
            // 音声トラックの存在確認（非同期API使用）
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            guard !audioTracks.isEmpty else {
                return .failure("音声トラックが見つかりません")
            }
            
            // 長さの取得（非同期API使用）
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            // 再生時間のチェック
            if durationSeconds <= 0 {
                return .failure("音声ファイルに有効な内容がありません（再生時間: \(durationSeconds)秒）")
            }
            
            // 最大10分のチェック
            if durationSeconds > 600 {
                return .failure("音声ファイルが長すぎます（最大10分）")
            }
            
            // ファイルサイズの最小チェック（1KB未満は無効）
            let fileSize = getFileSize(at: url)
            if fileSize < 1024 {
                return .failure("ファイルサイズが小さすぎます（\(fileSize)バイト）。有効な音声ファイルではない可能性があります。")
            }
            
            let audioFileInfo = AudioFileInfo(
                url: url,
                duration: durationSeconds,
                fileSize: getFileSize(at: url),
                format: fileExtension
            )
            
            print("✅ 音声ファイル検証成功:")
            print("- 再生時間: \(audioFileInfo.formattedDuration)")
            print("- ファイルサイズ: \(audioFileInfo.formattedFileSize)")
            print("- フォーマット: \(audioFileInfo.format)")
            
            return .success(audioFileInfo)
            
        } catch {
            return .failure("音声ファイルの解析に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    func copyToDocuments(from sourceURL: URL) -> URL? {
        print("📂 ファイルコピー開始:")
        print("- 元ファイル: \(sourceURL)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "uploaded_\(Date().timeIntervalSince1970).\(sourceURL.pathExtension)"
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        print("- コピー先: \(destinationURL)")
        
        // セキュリティスコープアクセス確認
        let accessSucceeded = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessSucceeded {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // 既存ファイルの削除
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                print("- 既存ファイル削除完了")
            }
            
            // ファイルコピー実行
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            print("✅ ファイルコピー成功")
            
            // コピー結果確認
            let copiedExists = FileManager.default.fileExists(atPath: destinationURL.path)
            print("- コピー結果確認: \(copiedExists)")
            
            return destinationURL
        } catch {
            print("❌ ファイルコピー失敗: \(error)")
            print("- Error type: \(type(of: error))")
            print("- Error description: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Models
enum ValidationResult {
    case success(AudioFileInfo)
    case failure(String)
}

struct AudioFileInfo: Identifiable {
    let id = UUID()
    let url: URL
    let duration: Double
    let fileSize: Int64
    let format: String
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}