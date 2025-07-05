# Xcode設定チェックリスト

## 1. Bundle Identifier設定
```
プロジェクト設定 → General → Identity
- Display Name: FillarGym
- Bundle Identifier: com.[あなたの名前].FillarGym
  例: com.hamazaki.FillarGym
- Version: 1.0.0
- Build: 1
```

## 2. Deployment Target
```
プロジェクト設定 → General → Deployment Info
- iOS 17.0以上に設定
- iPhone にチェック
- iPad は任意（Universal推奨）
```

## 3. App Icons設定
```
1. Assets.xcassets → AppIcon を右クリック
2. "Show in Finder"
3. 以下のサイズのアイコンを準備：
   - 1024x1024 (App Store)
   - 180x180 (iPhone @3x)
   - 120x120 (iPhone @2x)
   - その他必要なサイズ
```

## 4. Required Device Capabilities
```
プロジェクト設定 → Info → Required device capabilities
- arm64 （既に設定済み）
```

## 5. Privacy設定の確認
```
プロジェクト設定 → Info → Custom iOS Target Properties
確認項目：
- NSMicrophoneUsageDescription: 設定済み
- App Transport Security Settings: 必要に応じて
```

## 6. Capabilities確認
```
Signing & Capabilities タブ
現在有効：
- ✓ Automatically manage signing
- Team: [あなたのチーム選択]

今後追加可能：
- Push Notifications（通知機能追加時）
- Background Modes（バックグラウンド処理時）
```

## 7. Build Settings重要項目
```
Build Settings タブ（All/Combined表示）
- Product Bundle Identifier: 上記で設定したもの
- iOS Deployment Target: 17.0
- Swift Language Version: Swift 5
- Build Active Architecture Only: 
  - Debug: Yes
  - Release: No
```

## 8. Scheme設定
```
ツールバーのScheme → Edit Scheme
- Run → Release（提出前のテスト用）
- Archive → Release（必須）
```

## 9. アーカイブ前の最終確認
```
□ Bundle IDが正しい
□ Versionが1.0.0
□ Buildが1以上
□ Team選択済み
□ 証明書エラーなし
□ アイコン設定済み
□ FirebaseのGoogleService-Info.plist含まれている
□ Podfile.lockがコミットされている
```

## 10. アーカイブ作成
```
1. デバイス選択 → Any iOS Device (arm64)
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Archive
4. 成功したらOrganizerが開く
```

## トラブルシューティング

### "Team is not selected"エラー
→ Signing & Capabilities → Team選択

### "Provisioning profile doesn't include device"
→ Automatically manage signingをONに

### "No account for team"
→ Xcode → Settings → Accounts → Apple ID追加

### アーカイブが表示されない
→ Scheme設定でReleaseになっているか確認