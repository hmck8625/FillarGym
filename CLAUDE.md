# FillarGym - 開発ガイド

## プロジェクト概要

FillarGymは、音声録音からフィラー語（「えー」「あー」「その」など）を検出・分析し、話し方の改善を支援するiOSアプリです。

## 技術スタック

- **フレームワーク**: SwiftUI (iOS 17+)
- **データベース**: Core Data
- **API**: OpenAI (Whisper + GPT-4)
- **アーキテクチャ**: MVVM
- **セキュリティ**: Keychain Services

## 主要機能

### 1. 音声録音・分析
- リアルタイム音声録音
- ファイルアップロード対応
- Whisper APIによる文字起こし
- GPT-4によるフィラー語検出

### 2. カスタムフィラー語管理
- デフォルトフィラー語の有効/無効切り替え
- カスタムフィラー語の追加・編集・削除
- 日本語・英語対応

### 3. 分析結果表示
- フィラー語の種類・回数・位置
- 話速・フィラー率の計算
- 改善傾向のトラッキング

## 開発環境セットアップ

### 必要なもの
- Xcode 15.0+
- iOS 17.0+ シミュレータ/実機
- OpenAI API キー

### 環境変数設定
```bash
# Info.plistまたは環境変数に設定
OPENAI_API_KEY=your_api_key_here
```

### ビルド・テスト
```bash
# アプリビルド
xcodebuild -scheme FillarGym -destination 'platform=iOS Simulator,name=iPhone 15'

# テスト実行
xcodebuild test -scheme FillarGym -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Core Dataモデル

### エンティティ構造
```
AudioSession (録音セッション)
├── id: UUID
├── title: String?
├── duration: Double
├── filePath: String?
├── transcription: String?
├── createdAt: Date
└── analysis: FillerAnalysis?

FillerAnalysis (分析結果)
├── id: UUID
├── fillerCount: Int16
├── fillerRate: Double
├── speakingSpeed: Double
├── analysisDate: Date
├── audioSession: AudioSession
└── fillerWords: [FillerWord]

FillerWord (検出されたフィラー語)
├── id: UUID
├── word: String
├── count: Int16
├── confidence: Double
├── timestamp: Double
└── analysis: FillerAnalysis

UserSettings (ユーザー設定)
├── id: UUID
├── language: String
├── customFillerWords: String?
├── monthlyGoal: Int16
├── detectionSensitivity: Int16
├── isPremium: Bool
├── notificationEnabled: Bool
└── updatedAt: Date
```

## 重要な実装パターン

### Core Data安全な初期化
```swift
// 正しい方法
extension UserSettings {
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "UserSettings", in: context)!
        self.init(entity: entity, insertInto: context)
        // プロパティ設定
    }
}

// 間違った方法（無限再帰）
convenience init(context: NSManagedObjectContext) {
    self.init(context: context) // これはダメ！
}
```

### スレッドセーフなCore Data操作
```swift
viewContext.perform {
    // Core Data操作
    let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
    let results = try? viewContext.fetch(request)
    
    DispatchQueue.main.async {
        // UI更新
        self.userSettings = results?.first
    }
}
```

### 安全なファイルアクセス
```swift
let accessSucceeded = url.startAccessingSecurityScopedResource()
defer {
    if accessSucceeded {
        url.stopAccessingSecurityScopedResource()
    }
}
// ファイル操作
```

## よくある問題と解決方法

### 1. Core Data関連
- **問題**: EXC_BAD_ACCESS エラー
- **原因**: 無限再帰またはスレッド違反
- **解決**: 適切な初期化とスレッド管理

### 2. シート表示問題
- **問題**: 黒画面または表示されない
- **原因**: NavigationView競合または状態管理
- **解決**: `.sheet(item:)`使用、適切な状態更新

### 3. ファイルアップロード
- **問題**: "The view service did terminate" エラー
- **原因**: セキュリティスコープアクセス問題
- **解決**: 適切なリソース管理

## デバッグ・ログ

### 重要なログポイント
```swift
// Core Data操作
print("📋 UserSettings読み込み開始")

// ファイル操作
print("🔍 ファイル検証開始: \(url)")

// API通信
print("🔑 OpenAI API通信開始")

// エラー詳細
print("❌ エラー詳細: \(error.localizedDescription)")
```

## テスト戦略

### 単体テスト
- Core Dataモデルのテスト
- ビジネスロジックのテスト
- API通信のモックテスト

### 統合テスト
- 録音→分析→保存のフローテスト
- ファイルアップロード→分析のフローテスト
- 設定変更→反映のテスト

### UIテスト
- 基本的な画面遷移
- エラーハンドリングの確認
- アクセシビリティの検証

## パフォーマンス最適化

### Core Data
```swift
// クエリ最適化
request.fetchLimit = 1
request.includesSubentities = false
request.returnsObjectsAsFaults = false
```

### メモリ管理
```swift
// 適切なリソース解放
deinit {
    // 必要に応じてクリーンアップ
}
```

## セキュリティ考慮事項

### API キー管理
- Keychainでの安全な保存
- ハードコーディングの禁止
- 環境変数の活用

### ファイルアクセス
- Security Scoped Resource Access
- サンドボックス制限の遵守
- 一時ファイルの適切な削除

## リリース準備

### チェックリスト
- [ ] 全テストの実行
- [ ] メモリリークの確認
- [ ] パフォーマンステスト
- [ ] セキュリティ監査
- [ ] アクセシビリティ検証
- [ ] 多言語対応確認

### App Store 申請準備
- プライバシーポリシー
- 利用規約
- アプリ説明文
- スクリーンショット
- プレビュー動画

## 継続的改善

### 監視項目
- クラッシュレート
- API応答時間
- ユーザー満足度
- 分析精度

### フィードバック収集
- アプリ内レビュー
- クラッシュレポート
- ユーザーサポート
- アナリティクス

## 開発者向けリソース

### 参考ドキュメント
- [Apple Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [OpenAI API Documentation](https://platform.openai.com/docs)

### 開発ツール
- Xcode Instruments (パフォーマンス分析)
- Core Data Debugger
- Network Link Conditioner

## トラブルシューティング

### よくある質問
**Q: アプリがフリーズする**
A: Core Data操作がメインスレッドを阻害していないか確認

**Q: 分析結果が保存されない**
A: Core Data関係性が正しく設定されているか確認

**Q: ファイルアップロードが失敗する**
A: Security Scoped Resource Accessが適切に実装されているか確認

### エスカレーション
重大な問題が発生した場合は、`ERROR_FIXES.md`を参照し、既知の解決方法を確認してください。