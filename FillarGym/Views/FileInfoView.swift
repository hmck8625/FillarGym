import SwiftUI

struct FileInfoView: View {
    let fileInfo: AudioFileInfo
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // ファイルアイコン
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            // ファイル名
            Text(fileInfo.url.lastPathComponent)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // ファイル情報
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "フォーマット", value: fileInfo.format.uppercased())
                InfoRow(label: "長さ", value: fileInfo.formattedDuration)
                InfoRow(label: "サイズ", value: fileInfo.formattedFileSize)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // アクションボタン
            VStack(spacing: 12) {
                Button(action: {
                    print("📋 ファイル確認: 分析開始ボタンタップ")
                    dismiss()
                    // 少し遅らせてからonConfirmを呼ぶ
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onConfirm()
                    }
                }) {
                    Text("このファイルを分析")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    print("📋 ファイル確認: キャンセルボタンタップ")
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onCancel()
                    }
                }) {
                    Text("キャンセル")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .padding()
        .onAppear {
            print("📋 FileInfoView表示完了")
            print("- ファイル名: \(fileInfo.url.lastPathComponent)")
            print("- 再生時間: \(fileInfo.formattedDuration)")
            print("- ファイルサイズ: \(fileInfo.formattedFileSize)")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}