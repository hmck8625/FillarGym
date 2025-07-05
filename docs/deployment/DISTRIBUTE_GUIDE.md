# Archive後のDistribute手順

## 1. Organizerでの操作

### Archiveが完了すると自動的にOrganizerが開きます
（開かない場合: Window → Organizer）

### 「Distribute App」ボタンをクリック

## 2. 配布方法の選択

以下の選択肢が表示されます：

### 🎯 **App Store Connect** を選択（これを選ぶ）
- App Storeへの提出用
- TestFlight配信用

### その他の選択肢（今回は使わない）
- Ad Hoc: 特定デバイス向け配布
- Enterprise: 企業内配布
- Development: 開発用配布

→ **「Next」をクリック**

## 3. 配布オプション

### **Upload** を選択（推奨）
- App Store Connectに直接アップロード
- 最も簡単で一般的な方法

### Export（選ばない）
- IPAファイルとして書き出し
- 後で手動アップロードする場合

→ **「Next」をクリック**

## 4. App Store Connect配布オプション

以下のチェックボックスが表示されます：

### ✅ Include bitcode for iOS content
- ONのまま（Appleが最適化してくれる）

### ✅ Upload your app's symbols
- ONのまま（クラッシュレポート用）

### ✅ Manage Version and Build Number
- ONにすると自動でビルド番号を更新
- 初回はOFFでもOK

→ **「Next」をクリック**

## 5. 署名オプション

### 🎯 **Automatically manage signing** を選択（推奨）
- Xcodeが適切な証明書を自動選択
- 最も簡単

### Manually manage signing（上級者向け）
- 証明書を手動で選択

→ **「Next」をクリック**

## 6. Review画面

### 確認項目：
- Team: あなたのチーム名
- Certificate: Apple Distribution
- Profile: XC iOS: com.yourname.FillarGym
- Bundle ID: 正しいか確認

→ **「Upload」をクリック**

## 7. アップロード処理

### アップロード中の表示
- プログレスバーが表示される
- 5-15分程度かかる場合がある
- 回線速度による

### よくあるエラー

#### "No suitable application records found"
```
解決方法：
1. App Store Connectでアプリを作成していない
2. Bundle IDが一致していない
→ App Store Connectでアプリ作成が必要
```

#### "Invalid Bundle ID"
```
解決方法：
Bundle IDを確認して修正
```

#### "Version already exists"
```
解決方法：
Version番号を上げる（1.0.0 → 1.0.1）
```

## 8. アップロード完了

### 成功時の表示
- "Upload Successful" メッセージ
- App Store Connectで処理中になる

### 次のステップ
1. App Store Connectにログイン
2. 「マイApp」→ FillarGym
3. 「TestFlight」または「App Store」タブ
4. ビルドが表示されるまで待つ（15-30分）

## 9. App Store Connectでの確認

### ビルド処理状況
- **処理中**: 15-30分待つ
- **処理完了**: 使用可能
- **無効**: エラーがある（メール確認）

### ビルドが表示されたら
1. ビルド番号をクリック
2. 輸出コンプライアンス情報を入力
   - 暗号化を使用していない → いいえ
3. TestFlightでテスト（任意）
4. App Store提出準備へ

## トラブルシューティング

### アップロードが進まない
- ネットワーク接続確認
- Xcodeを再起動
- Application Loaderを使用（古い方法）

### "Cannot verify client"エラー
- Xcode → Settings → Accountsで再ログイン
- 2ファクタ認証の確認

### ビルドが表示されない
- 30分以上待つ
- メールでエラー通知を確認
- App Store Connect → アクティビティで確認