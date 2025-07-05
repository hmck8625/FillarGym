# FillarGym ビルド・セットアップガイド

## 📋 事前準備

### 必要な環境
- **Xcode 15.0以降**
- **iOS 17.0以降** の対応デバイスまたはシミュレーター
- **macOS Sonoma以降**
- **Apple Developer Account**（実機テスト時）

## 🔧 Xcode プロジェクト設定

### 1. プロジェクトを開く
```bash
cd /Users/hamazakidaisuke/Desktop/filargym/FillarGym
open FillarGym.xcodeproj
```

### 2. Info.plist設定（必須）

**手順：**
1. Xcodeでプロジェクトナビゲーターを開く
2. `FillarGym`プロジェクトを選択
3. `TARGETS` → `FillarGym` を選択
4. `Info`タブを開く
5. **Custom iOS Target Properties** で以下を追加：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>音声録音機能を使用して、フィラー語の分析を行います。録音データはデバイス内にのみ保存され、分析のためOpenAI APIに一時的に送信されます。</string>
```

**または、Info.plistファイルを直接編集：**
1. プロジェクトナビゲーターで `Info.plist` を探す
2. ファイルを右クリック → `Open As` → `Source Code`
3. `</dict>`の前に上記のキーと値を追加

### 3. Bundle Identifier設定
1. `TARGETS` → `FillarGym` → `General`タブ
2. **Bundle Identifier**を一意のものに変更：
   例：`com.yourname.fillargym`

### 4. Team設定（実機テスト時）
1. **Signing & Capabilities**タブを開く
2. **Team**で自分のApple Developer Accountを選択
3. **Automatically manage signing**にチェック

## 🔑 OpenAI API設定（任意）

### 方法1: Xcode Scheme環境変数設定（推奨）

1. **Product** → **Scheme** → **Edit Scheme...**
2. **Run**を選択
3. **Arguments**タブ → **Environment Variables**
4. `+`ボタンで以下を追加：
   - **Name**: `OPENAI_API_KEY`
   - **Value**: `your-openai-api-key-here`

### 方法2: ハードコーディング（開発時のみ）

`OpenAIService.swift`を編集：
```swift
init() {
    // 開発時のみ - 本番では絶対に使用しない
    self.apiKey = "your-openai-api-key-here"
    
    // または環境変数から取得（推奨）
    // self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
}
```

**⚠️ 注意：ハードコーディングは本番環境では絶対に使用しないでください**

### OpenAI API Key取得方法
1. [OpenAI Platform](https://platform.openai.com/)にアクセス
2. アカウント作成・ログイン
3. **API Keys**セクションで新しいキーを作成
4. 作成されたキーをコピー（二度と表示されません）

## 🏗️ ビルド手順

### 1. 依存関係の確認
プロジェクトに外部ライブラリはありませんが、以下のフレームワークが正しくリンクされているか確認：

1. **TARGETS** → **FillarGym** → **General** → **Frameworks, Libraries, and Embedded Content**
2. 以下が含まれていることを確認：
   - `AVFoundation.framework`
   - `CoreData.framework`
   - `Charts.framework`（iOS 16.0以降）

### 2. ビルド実行

**シミュレーターでのビルド：**
1. Xcodeの上部でターゲットデバイスを選択（例：iPhone 15 Pro Simulator）
2. **⌘ + B**（Build）または**⌘ + R**（Build and Run）

**実機でのビルド：**
1. iPhoneをUSBケーブルで接続
2. デバイスを信頼し、開発者モードを有効化
3. Xcodeでデバイスを選択
4. **⌘ + R**でビルド・実行

## 🧪 機能テスト手順

### 1. 基本機能テスト

#### アプリ起動テスト
- [ ] アプリが正常に起動する
- [ ] タブバーが表示される
- [ ] 各タブ（ホーム、履歴、分析、設定）が機能する

#### 権限テスト
- [ ] 初回録音時にマイク権限ダイアログが表示される
- [ ] 「許可」選択後、録音が可能になる
- [ ] 「許可しない」選択時、適切なエラーメッセージが表示される

### 2. 録音機能テスト

#### 録音操作テスト
- [ ] ホーム画面の「録音開始」ボタンが機能する
- [ ] 録音画面が正しく表示される
- [ ] 録音中に音声レベルが表示される
- [ ] 経過時間が正しくカウントされる
- [ ] 録音停止ボタンが機能する

#### 録音データテスト
- [ ] 録音ファイルが正しく保存される
- [ ] Core Dataにセッション情報が保存される
- [ ] 録音時間が正確に記録される

### 3. 分析機能テスト

#### モック分析テスト（API Key未設定時）
- [ ] 録音完了後、分析処理画面が表示される
- [ ] プログレスバーが進行する
- [ ] モック分析結果が生成される
- [ ] 分析結果画面が正しく表示される

#### 実際のAPI分析テスト（API Key設定時）
- [ ] OpenAI APIとの通信が成功する
- [ ] 文字起こしが正常に実行される
- [ ] フィラー語検出が機能する
- [ ] 分析結果が適切に保存される

### 4. UI・UX テスト

#### ナビゲーションテスト
- [ ] 各タブ間の遷移が正常
- [ ] 各画面の戻るボタンが機能する
- [ ] モーダル画面の閉じるボタンが機能する

#### データ表示テスト
- [ ] 履歴画面でセッション一覧が表示される
- [ ] 分析画面でグラフ・統計が表示される
- [ ] 設定画面で各種設定が保存される

### 5. エラーハンドリングテスト

#### ネットワークエラーテスト
- [ ] インターネット接続なしでの動作
- [ ] API制限エラーの処理
- [ ] タイムアウトエラーの処理

#### データエラーテスト
- [ ] 不正な音声ファイルの処理
- [ ] Core Dataエラーの処理
- [ ] ストレージ不足時の処理

## 🐛 トラブルシューティング

### よくある問題と解決方法

#### 1. ビルドエラー

**問題**: `NSMicrophoneUsageDescription` エラー
```
This app has crashed because it attempted to access privacy-sensitive data without a usage description.
```
**解決方法**: Info.plistにマイク使用許可の説明を追加（上記手順参照）

**問題**: Core Dataエラー
```
The model used to open the store is incompatible with the one used to create the store
```
**解決方法**: 
1. シミュレーター → Device → Erase All Content and Settings
2. または実機のアプリを削除して再インストール

#### 2. 実行時エラー

**問題**: 録音ができない
**確認事項**:
- [ ] マイク権限が許可されているか
- [ ] デバイスのマイクが正常に動作するか
- [ ] 他のアプリがマイクを使用していないか

**問題**: 分析でエラーが発生
**確認事項**:
- [ ] インターネット接続があるか
- [ ] OpenAI API Keyが正しく設定されているか
- [ ] API使用制限に達していないか

#### 3. パフォーマンス問題

**問題**: アプリが重い・遅い
**確認事項**:
- [ ] 古いデバイス（iPhone 12以前）での動作確認
- [ ] 大量のデータが蓄積されていないか
- [ ] メモリリークが発生していないか

### デバッグ方法

#### 1. コンソールログの確認
```swift
// デバッグ用ログを追加
print("録音開始: \(Date())")
print("API Key存在: \(!apiKey.isEmpty)")
print("Core Data保存成功")
```

#### 2. Xcode Instrumentsの使用
1. **Product** → **Profile**
2. **Leaks**テンプレートでメモリリーク検出
3. **Time Profiler**でパフォーマンス分析

#### 3. デバイスログの確認
1. **Window** → **Devices and Simulators**
2. デバイスを選択 → **Open Console**
3. `FillarGym`でフィルタリング

## 🚀 リリース準備

### App Store提出前チェックリスト

#### 1. メタデータ確認
- [ ] アプリ名
- [ ] バンドルID
- [ ] バージョン番号
- [ ] ビルド番号

#### 2. プライバシー設定
- [ ] プライバシーポリシーの準備
- [ ] データ使用に関する説明
- [ ] サードパーティSDKの開示

#### 3. テスト完了
- [ ] 全機能テスト完了
- [ ] 複数デバイスでの動作確認
- [ ] リリースビルドでの最終確認

## 📞 サポート

問題が解決しない場合：
1. XcodeのClean Build Folder実行
2. 派生データの削除
3. プロジェクトの再クローン
4. 開発チームへの相談

---

このガイドに従って、FillarGymアプリを正常にビルド・テストできるはずです。
何か問題が発生した場合は、エラーメッセージとともにお知らせください。