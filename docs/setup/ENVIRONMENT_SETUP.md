# 環境変数設定ガイド

## OpenAI APIキーの設定方法

FillarGymアプリでは、OpenAI APIキーを環境変数で管理します。以下の方法で設定してください。

## 開発環境での設定

### 方法1: Xcode Scheme設定（推奨）

1. Xcodeでプロジェクトを開く
2. **Product** → **Scheme** → **Edit Scheme...**
3. **Run** → **Arguments** → **Environment Variables**
4. `+` ボタンをクリックして以下を追加：
   - **Name**: `OPENAI_API_KEY`
   - **Value**: `your-openai-api-key-here`

### 方法2: Xcode Build Settings

1. プロジェクトファイルを選択
2. **TARGETS** → **FillarGym** → **Build Settings**
3. `+` ボタン → **Add User-Defined Setting**
4. **Setting Name**: `OPENAI_API_KEY_PROD`
5. **Value**: `your-openai-api-key-here`

## 本番環境での設定

### GitHub Actions (CI/CD)

`.github/workflows/build.yml` ファイル例：

```yaml
name: Build FillarGym

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Install dependencies
      run: pod install
    
    - name: Build
      run: |
        xcodebuild \
          -workspace FillarGym.xcworkspace \
          -scheme FillarGym \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
          OPENAI_API_KEY_PROD="${{ secrets.OPENAI_API_KEY }}" \
          build
```

### GitHub Secrets設定

1. GitHubリポジトリページで **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** をクリック
3. **Name**: `OPENAI_API_KEY`
4. **Value**: 実際のOpenAI APIキー
5. **Add secret** で保存

### App Store Archive

1. Xcodeで **Product** → **Archive**
2. Archive時に環境変数を設定：
   ```bash
   OPENAI_API_KEY_PROD=your-api-key-here xcodebuild archive \
     -workspace FillarGym.xcworkspace \
     -scheme FillarGym \
     -archivePath FillarGym.xcarchive
   ```

## セキュリティ注意事項

### ✅ 推奨される方法
- GitHub Secrets使用
- 環境変数での管理
- Xcode Build Settings
- CI/CDパイプラインでの注入

### ❌ 避けるべき方法
- ソースコードにハードコード
- Info.plistに直接記載
- gitリポジトリにコミット
- 平文でのファイル保存

## トラブルシューティング

### APIキーが認識されない場合

1. **環境変数の確認**:
   ```swift
   // デバッグ用コード
   print("環境変数: \(ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "なし")")
   print("Info.plist: \(Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY_PROD") ?? "なし")")
   ```

2. **Clean Build**:
   - **Product** → **Clean Build Folder** (⌘+Shift+K)
   - プロジェクトを再ビルド

3. **スキーム確認**:
   - Edit Scheme → Run → Arguments → Environment Variables
   - 正しく設定されているか確認

### 本番ビルドでAPIキーが空の場合

1. **Build Settings確認**:
   - User-Defined Settingsに `OPENAI_API_KEY_PROD` があるか
   - 値が正しく設定されているか

2. **Archive設定**:
   - Archive時のBuild Configurationが正しいか
   - 環境変数が渡されているか

## 開発フロー

### 新しい開発者向け
1. リポジトリをクローン
2. `docs/setup/QUICK_START.md` に従ってセットアップ
3. 自分のOpenAI APIキーをXcode Schemeに設定
4. アプリをビルド・実行

### リリース担当者向け
1. GitHub SecretsにAPIキーを設定
2. GitHub Actionsでビルド確認
3. Archive時にAPIキーを環境変数で指定
4. App Store Connectにアップロード

---

この設定により、APIキーをソースコードから完全に分離し、セキュアに管理できます。