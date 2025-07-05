# Firebase Analytics セットアップ手順

## 1. CocoaPods インストール

```bash
# FillarGymディレクトリで実行
cd /Users/hamazakidaisuke/Desktop/filargym/FillarGym
pod install
```

## 2. Xcodeプロジェクトを開く

```bash
# .xcworkspaceファイルを開く（重要！）
open FillarGym.xcworkspace
```

## 3. GoogleService-Info.plist をXcodeに追加

1. Xcodeで FillarGym プロジェクトを選択
2. FillarGym フォルダを右クリック → "Add Files to FillarGym"
3. `GoogleService-Info.plist` を選択
4. "Add to target" で FillarGym にチェックが入っていることを確認
5. "Add" をクリック

## 4. Firebase インポートを有効化

### FillarGymApp.swift
```swift
// コメントアウトを解除
import FirebaseCore

// init() 内のコメントアウトを解除
FirebaseApp.configure()
```

### AnalyticsManager.swift
```swift
// コメントアウトを解除
import FirebaseAnalytics

// 各メソッド内のAnalytics.logEventのコメントアウトを解除
```

## 5. ビルド設定の確認

### Target Settings
1. FillarGym ターゲットを選択
2. "Build Settings" タブ
3. "Other Linker Flags" に以下が追加されていることを確認：
   - `-ObjC`
   - `-framework "FirebaseAnalytics"`

### Info.plist
必要に応じて以下を追加：
```xml
<key>FirebaseAutomaticScreenReportingEnabled</key>
<false/>
```

## 6. 動作確認

### デバッグコンソールの確認
```
📊 Analytics: App session started
📊 Analytics: Screen view - onboarding_view (OnboardingView)
```

### Firebase Console での確認
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクトを選択
3. Analytics → Events でリアルタイムイベントを確認

## 7. 実装済み機能

### 基本計測
- [x] アプリセッション開始/終了
- [x] 画面遷移トラッキング
- [x] ユーザープロパティ設定

### Analytics同意機能
- [x] プライバシー設定画面
- [x] 同意状態の永続化
- [x] 設定画面からの変更

### 準備済みイベント
- [x] 録音開始/完了
- [x] 分析開始/完了
- [x] ファイルアップロード
- [x] カスタムフィラー語操作
- [x] エラートラッキング

## 8. 次のステップ

### Firebase有効化後に実行する作業
1. `AnalyticsManager.swift` のコメントアウト解除
2. `FillarGymApp.swift` のFirebase初期化コメントアウト解除
3. 実際のイベント送信確認
4. Firebase Consoleでのデータ確認

### イベント実装
- 各Viewでの画面遷移トラッキング
- ボタンクリックイベントの追加
- カスタムイベントの実装

## 9. 注意事項

### プライバシー
- ユーザーの同意なしにはデータ収集を行わない
- App Store 申請時にプライバシーポリシーを更新
- 録音内容や個人情報は収集しない

### デバッグ
- デバッグビルドでは実際のイベント送信を確認
- リリースビルドでの動作テスト
- Firebase Console でのリアルタイム確認

## 10. トラブルシューティング

### よくある問題
1. **GoogleService-Info.plistが見つからない**
   - ファイルがプロジェクトに正しく追加されているか確認
   - Bundle ID が一致しているか確認

2. **イベントが表示されない**
   - Firebase Console で数分〜数時間待つ
   - デバッグビューを使用してリアルタイム確認

3. **ビルドエラー**
   - `.xcworkspace` ファイルを使用しているか確認
   - pod install を再実行

4. **Sandbox rsyncエラー**
   - Clean build folderを実行 (⇧⌘K)
   - DerivedDataディレクトリを削除
   - Xcodeを再起動してから再ビルド

### 確認コマンド
```bash
# Podfile の依存関係確認
pod list

# Firebase SDKバージョン確認
pod list | grep Firebase

# DerivedDataクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 現在の実装状況

#### ✅ 完了済み
- [x] CocoaPods統合
- [x] Firebase/Analytics SDKインストール
- [x] AnalyticsManager.swiftの実装
- [x] FillarGymApp.swiftでのFirebase初期化
- [x] AnalyticsConsentView実装
- [x] 基本的なイベントトラッキング設定

#### ⚠️ 既知の問題
- Firebaseフレームワークのsandbox権限エラー
  - 回避方法：Xcodeでクリーンビルド後、直接.xcworkspaceを開いてビルド

#### 🔄 次に必要な作業
1. Xcodeで`.xcworkspace`ファイルを直接開く
2. GoogleService-Info.plistがプロジェクトに追加されているか確認
3. クリーンビルド実行
4. 実機またはシミュレータでテスト実行