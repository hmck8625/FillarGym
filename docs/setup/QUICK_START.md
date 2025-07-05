# 🚀 FillarGym クイックスタート

## 最短ビルド手順（5分）

### 1. プロジェクトを開く
```bash
open /Users/hamazakidaisuke/Desktop/filargym/FillarGym/FillarGym.xcodeproj
```

### 2. 必須設定（1分）
**Info.plist設定：**
1. プロジェクトナビゲーター → `FillarGym` → `TARGETS` → `FillarGym` → `Info`
2. `+`ボタンをクリック
3. キー: `Privacy - Microphone Usage Description`
4. 値: `音声録音機能を使用してフィラー語を分析します`

### 3. ビルド実行（1分）
1. シミュレーター選択（iPhone 15 Pro推奨）
2. **⌘ + R**でビルド・実行

### 4. 基本テスト（3分）
1. ✅ アプリ起動確認
2. ✅ ホーム画面で「録音開始」タップ
3. ✅ マイク権限「許可」
4. ✅ 30秒程度話して録音停止
5. ✅ 分析完了後、結果画面確認

## OpenAI API設定（任意）

実際のAI分析を試したい場合：

1. **Scheme設定：**
   - Product → Scheme → Edit Scheme...
   - Run → Arguments → Environment Variables
   - `OPENAI_API_KEY` = `your-api-key`

2. **API Key取得：**
   - [OpenAI Platform](https://platform.openai.com/) でアカウント作成
   - API Keys から新しいキー作成

## トラブル時のクイック解決

| 問題 | 解決方法 |
|------|----------|
| ビルドエラー | ⌘ + Shift + K でClean → 再ビルド |
| マイク権限エラー | Info.plist設定確認 |
| Core Dataエラー | シミュレーター初期化 |
| 分析エラー | ネット接続・API Key確認 |

**🎉 これで基本的なフィラー語検出アプリが動作します！**