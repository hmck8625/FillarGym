# セットアップ手順

## 必要な設定

### Info.plist設定
Xcodeプロジェクトの Info.plist に以下のキーを追加してください：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>音声録音機能を使用して、フィラー語の分析を行います。</string>
```

### 必要なフレームワーク
- AVFoundation.framework (音声録音)
- CoreData.framework (データ保存)
- Charts.framework (iOS 16.0以降でグラフ表示)

### プロジェクト設定
1. Deployment Target: iOS 17.0
2. Privacy - Microphone Usage Description を設定
3. Background Modes で Audio を有効化（必要に応じて）

### 依存関係
- OpenAI API Key (環境変数またはConfiguration)
- ネットワーク通信許可

## 実装完了機能
✅ Core Dataデータモデル設計
✅ タブベースUI構造
✅ 音声録音機能（AVFoundation）
✅ OpenAI API通信サービス
✅ 分析結果表示
✅ 履歴・進捗トラッキング
✅ 設定画面（フィラー語設定、データ管理）

## 追加実装推奨機能
1. 課金システム（StoreKit 2）
2. プッシュ通知機能
3. オンボーディング画面
4. データ同期（iCloud）
5. ウィジェット対応
6. Apple Watch対応

## ビルド・テスト手順
1. Xcodeでプロジェクトを開く
2. Info.plist設定を確認
3. OpenAI API Key環境変数を設定（任意）
4. シミュレーターまたは実機でビルド
5. マイク権限の許可を確認
6. 録音→分析フローをテスト

## トラブルシューティング
- 録音できない → マイク権限を確認
- 分析でエラー → OpenAI API Keyの設定確認
- データが表示されない → Core Dataの初期化確認