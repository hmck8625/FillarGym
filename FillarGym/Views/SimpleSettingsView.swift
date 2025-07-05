import SwiftUI

struct SimpleSettingsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("FillarGym")
                            .font(.headline)
                        Text("Free会員")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button("アップグレード") {
                        print("Premium upgrade tapped")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section("基本設定") {
                HStack {
                    Text("月間目標録音数")
                    Spacer()
                    Text("10回")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("言語")
                    Spacer()
                    Text("日本語")
                        .foregroundColor(.gray)
                }
            }
            
            Section("アプリ情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("設定")
    }
}