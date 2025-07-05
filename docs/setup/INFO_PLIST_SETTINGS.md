# Info.plist 必須設定

## 🔧 Xcodeでの設定手順

### 1. プロジェクト設定を開く
1. Xcodeでプロジェクトナビゲーターの **FillarGym** をクリック
2. **TARGETS** → **FillarGym** を選択
3. **Info** タブを開く

### 2. 必須項目を追加

**Custom iOS Target Properties** セクションで `+` ボタンを押して以下を追加：

#### マイク使用許可（必須）
- **Key**: `Privacy - Microphone Usage Description`
- **Type**: `String`
- **Value**: `音声録音機能を使用してフィラー語を分析します`

#### ファイルサポート設定（警告解消）
- **Key**: `Supports opening documents in place`
- **Type**: `Boolean`
- **Value**: `NO`

## 📝 Info.plist ソースコード形式

Info.plistを直接編集する場合：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>音声録音機能を使用してフィラー語を分析します</string>

<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

## ✅ 設定完了後

1. **⌘ + Shift + K** でクリーンビルド
2. **⌘ + R** でビルド・実行

これで警告とエラーが解消されます！