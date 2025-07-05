# FillarGym - App Store 提出ガイド

## 1. 証明書の作成

### Distribution Certificate（配布証明書）
1. Xcode → Preferences → Accounts
2. Apple IDを選択 → Manage Certificates
3. "+" ボタン → Apple Distribution

### App ID の作成
1. Apple Developer Portal → Certificates, IDs & Profiles
2. Identifiers → "+" → App IDs
3. Bundle ID: `com.yourcompany.FillarGym`
4. Capabilities:
   - ✅ Push Notifications（将来用）
   - ✅ Associated Domains（将来用）

### Provisioning Profile
1. Profiles → "+" → App Store
2. App IDを選択
3. Distribution Certificateを選択
4. プロファイル名: `FillarGym AppStore`

## 2. Xcode プロジェクト設定

```bash
# Info.plist 確認項目
- CFBundleDisplayName: FillarGym
- CFBundleShortVersionString: 1.0.0
- CFBundleVersion: 1
- NSMicrophoneUsageDescription: 録音機能を使用してフィラー語を分析します
- UILaunchStoryboardName: LaunchScreen
```

### Build Settings
- Product Bundle Identifier: `com.yourcompany.FillarGym`
- iOS Deployment Target: 17.0
- Build Configuration: Release
- Code Signing:
  - Team: [Your Team]
  - Provisioning Profile: FillarGym AppStore
  - Code Signing Identity: Apple Distribution

## 3. アプリアイコンとスクリーンショット

### アプリアイコン（必須）
- 1024x1024px（App Store用）
- アイコンセットに全サイズ含める

### スクリーンショット（必須）
- 6.7インチ（iPhone 15 Pro Max）: 1290 x 2796
- 6.5インチ（iPhone 14 Plus）: 1284 x 2778  
- 5.5インチ（iPhone 8 Plus）: 1242 x 2208
- iPad Pro 12.9インチ: 2048 x 2732

各デバイスサイズで最低3枚、最大10枚

## 4. App Store Connect 設定

### 基本情報
```
アプリ名: FillarGym - フィラー語改善トレーナー
サブタイトル: 話し方の「えー」「あー」を減らそう
カテゴリ: 教育 / 仕事効率化
```

### アプリ説明文（4000文字以内）
```
FillarGymは、あなたの話し方を改善するためのパーソナルトレーナーです。

【こんな方におすすめ】
• プレゼンや会議で「えー」「あー」が多いと感じる方
• 就職活動の面接対策をしたい方
• YouTuberやポッドキャスターとして話し方を改善したい方
• 営業職で説得力のある話し方を身につけたい方

【主な機能】
• 音声録音とリアルタイム分析
• AIによる高精度なフィラー語検出
• 詳細な分析レポート（フィラー率、話速、改善推移）
• カスタムフィラー語の設定
• 録音履歴と進捗管理
• ファイルアップロード対応

【FillarGymの特徴】
• OpenAI技術による正確な音声認識
• プライバシー重視（録音データはローカル保存）
• 日本語・英語対応
• 直感的で使いやすいUI
• 定期的な練習を促す目標設定機能

【使い方】
1. 録音ボタンをタップして話し始める
2. 1-10分程度の録音を行う
3. 自動分析でフィラー語を検出
4. 結果を確認して改善ポイントを把握
5. 定期的に練習して上達を実感

話し方を改善して、より説得力のあるコミュニケーションを実現しましょう！
```

### キーワード（100文字）
```
フィラー語,えー,あー,話し方,改善,プレゼン,スピーチ,面接,練習,録音,分析,AI,トレーニング
```

### What's New（4000文字以内）
```
バージョン 1.0.0
• FillarGym 初回リリース
• 音声録音と分析機能
• カスタムフィラー語設定
• 進捗トラッキング
• 日本語・英語対応
```

### プライバシーポリシーURL
```
https://yourdomain.com/fillargym/privacy
```

### サポートURL
```
https://yourdomain.com/fillargym/support
```

## 5. アーカイブとアップロード

### Xcodeでアーカイブ作成
1. Scheme → FillarGym
2. Device → Any iOS Device
3. Product → Archive
4. Organizer → Distribute App
5. App Store Connect → Next
6. Upload → Next
7. Automatically manage signing → Next
8. Upload

### App Store Connect でビルド選択
1. マイApp → FillarGym
2. TestFlight または App Store
3. ビルドを選択

## 6. 審査情報

### デモアカウント（必要な場合）
```
不要（ログイン機能なし）
```

### 審査メモ
```
本アプリは音声録音機能を使用してフィラー語（「えー」「あー」など）を
検出・分析するアプリです。録音データはデバイス内にのみ保存され、
外部サーバーへの送信は行いません。

OpenAI APIを使用していますが、音声データ自体は送信せず、
文字起こし結果のみを送信しています。
```

### 連絡先情報
```
名前: [Your Name]
メールアドレス: [Your Email]
電話番号: [Your Phone]
```

## 7. 価格と販売地域

### 価格設定
- 無料 / Tier 1（¥160）など選択
- 自動価格調整: オン推奨

### 販売地域
- すべての地域 または 日本のみ

## 8. 年齢制限

### レーティング
- 4+ （教育アプリとして）
- 暴力的コンテンツ: なし
- 成人向けコンテンツ: なし
- ギャンブル: なし

## 9. 審査提出前の最終チェック

- [ ] すべてのクラッシュを修正
- [ ] メモリリークがないことを確認
- [ ] 全画面でレイアウト崩れがない
- [ ] ネットワークエラー時の処理
- [ ] 空の状態の適切な表示
- [ ] プライバシーポリシーが最新
- [ ] すべての機能が動作する
- [ ] 不適切なコンテンツがない
- [ ] テストデータが含まれていない
- [ ] デバッグログが無効化されている

## 10. 審査対応

### よくあるリジェクト理由
1. **Guideline 2.1**: アプリがクラッシュする
2. **Guideline 4.1**: コンテンツが不適切
3. **Guideline 5.1.1**: データ収集の説明不足

### リジェクト時の対応
1. Resolution Centerで詳細を確認
2. 指摘された問題を修正
3. 修正内容を明確に説明して再提出

## 11. リリース後の対応

### App Analytics 確認
- ダウンロード数
- クラッシュ率
- ユーザーレビュー

### アップデート計画
- ユーザーフィードバックの収集
- バグ修正（2週間以内）
- 新機能追加（1-2ヶ月ごと）
