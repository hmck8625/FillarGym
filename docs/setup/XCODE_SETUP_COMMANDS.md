# Xcode Firebase Analytics セットアップ用コマンド

## 基本的なトラブルシューティング

### 1. CocoaPods関連
```bash
# プロジェクトディレクトリに移動
cd /Users/hamazakidaisuke/Desktop/filargym/FillarGym

# Podの再インストール
pod deintegrate
pod install

# Podの更新
pod update

# インストール済みPod確認
pod list | grep Firebase
```

### 2. Xcodeキャッシュクリア
```bash
# DerivedDataクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Xcodeキャッシュクリア
xcrun simctl erase all

# ModuleCacheクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache/*
```

### 3. プロジェクトファイル確認
```bash
# GoogleService-Info.plistの存在確認
ls -la /Users/hamazakidaisuke/Desktop/filargym/FillarGym/FillarGym/GoogleService-Info.plist

# .xcworkspaceファイルの確認
ls -la /Users/hamazakidaisuke/Desktop/filargym/FillarGym/*.xcworkspace

# Podfile.lockの確認
cat /Users/hamazakidaisuke/Desktop/filargym/FillarGym/Podfile.lock | grep Firebase
```

### 4. ビルド確認コマンド
```bash
# コマンドラインビルド（デバッグ用）
xcodebuild -workspace FillarGym.xcworkspace -scheme FillarGym -destination 'platform=iOS Simulator,name=iPhone 16' build

# 利用可能なシミュレータ一覧
xcrun simctl list devices

# 利用可能なスキーム確認
xcodebuild -workspace FillarGym.xcworkspace -list
```

## Firebase Console URLs

### プロジェクト管理
- Firebase Console: https://console.firebase.google.com/
- Analytics Events: https://console.firebase.google.com/project/YOUR_PROJECT_ID/analytics/events
- Real-time Events: https://console.firebase.google.com/project/YOUR_PROJECT_ID/analytics/events?tab=realtime

### デバッグ用
- Debug View: https://console.firebase.google.com/project/YOUR_PROJECT_ID/analytics/debugview

## よくある問題と解決方法

### 問題1: "No such module 'FirebaseAnalytics'"
```bash
# 解決手順
cd /Users/hamazakidaisuke/Desktop/filargym/FillarGym
pod install
# Xcodeを再起動
open FillarGym.xcworkspace
```

### 問題2: ビルドは成功するがイベントが送信されない
```bash
# シミュレータのリセット
xcrun simctl erase all
# アプリの再インストール
```

### 問題3: GoogleService-Info.plistが認識されない
```
Xcode操作が必要：
1. ファイルをプロジェクトに再追加
2. Target membershipの確認
3. Bundle IDの一致確認
```

## 成功時の確認ポイント

### Xcodeコンソールログ
```
📊 Analytics: App session started
📊 Analytics: Screen view - onboarding_view (OnboardingView)
📊 Analytics: User property - app_version: 1.0.0
```

### Firebase Console確認事項
- Real-time events にイベントが表示される
- User properties が設定されている
- Session データが記録されている

## 緊急時の完全リセット
```bash
# 全キャッシュクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*
cd /Users/hamazakidaisuke/Desktop/filargym/FillarGym
pod deintegrate
pod install
# Xcodeを再起動後、.xcworkspaceを開く
```