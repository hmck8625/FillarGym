# FillarGym App Store提出 ステップバイステップガイド

## 今すぐやること

### ステップ1: Apple Developer登録確認
```bash
# ブラウザで確認
https://developer.apple.com/account

# 必要なら登録（年間$99）
https://developer.apple.com/programs/enroll/
```

### ステップ2: Xcodeでプロジェクト設定
1. FillarGym.xcworkspaceを開く
2. FillarGymターゲットを選択
3. Signing & Capabilities タブ
   - Team: 自分のDeveloper Team選択
   - Bundle Identifier: `com.yourcompany.FillarGym`に変更

### ステップ3: 必須アイコン作成
```bash
# 最低限必要なもの
1. 1024x1024px のアイコンを作成
2. https://appicon.co/ でアイコンセット生成
3. Assets.xcassets → AppIcon に配置
```

### ステップ4: Info.plist確認
```xml
<!-- 以下が設定されているか確認 -->
<key>NSMicrophoneUsageDescription</key>
<string>録音機能を使用してフィラー語を分析します</string>
```

### ステップ5: アーカイブ作成
```bash
1. Scheme → FillarGym
2. Device → Any iOS Device (arm64)
3. Product → Archive
4. 完了まで待つ（5-10分）
```

### ステップ6: App Store Connect設定
```bash
# ブラウザで開く
https://appstoreconnect.apple.com

1. マイApp → 「+」 → 新規App
2. プラットフォーム: iOS
3. 名前: FillarGym
4. プライマリ言語: 日本語
5. バンドルID: 作成したものを選択
6. SKU: fillargym-v1
7. 作成
```

### ステップ7: 基本情報入力
```
カテゴリ: 
- プライマリ: 教育
- セカンダリ: 仕事効率化

価格: 0円（無料）

年齢制限: 4+
```

### ステップ8: スクリーンショット準備
```bash
# シミュレータで撮影
1. iPhone 15 Pro Maxシミュレータ起動
2. 各画面でCommand + S
3. 最低3枚、推奨5枚
```

### ステップ9: アップロード
```bash
1. Xcode → Organizer
2. 作成したアーカイブ選択
3. Distribute App
4. App Store Connect
5. Upload
6. 自動署名を選択
7. アップロード完了待ち
```

### ステップ10: 審査提出
```bash
1. App Store Connect → FillarGym
2. 提出準備中 → ビルド選択
3. 必須情報すべて入力
4. 「審査へ提出」クリック
```

## よくあるトラブルと解決方法

### エラー: "No account for team"
→ Xcode → Preferences → Accounts でApple ID追加

### エラー: "Profile doesn't include the selected device"
→ Automatically manage signingをON

### エラー: "Missing Info.plist key"
→ Info.plistに必要なUsageDescription追加

### エラー: "Invalid Bundle ID"
→ Bundle IDを`com.yourname.FillarGym`形式に

## 審査期間
- 通常: 24-48時間
- 初回提出: 最大7日間
- リジェクト後の再提出: 24時間

## 緊急時の対応
もし詰まったら：
1. エラーメッセージをGoogle検索
2. Apple Developer Forums確認
3. Stack Overflow検索