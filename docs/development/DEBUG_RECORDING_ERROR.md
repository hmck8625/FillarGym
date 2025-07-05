# 録音保存エラーのデバッグ手順

## エラー内容
「録音の保存に失敗しました。（multiple validation errors occurred）」

## デバッグ手順

### 1. Xcodeでデバッグ情報を有効化
1. Xcode → Product → Scheme → Edit Scheme
2. Run → Arguments → Arguments Passed On Launch
3. 以下を追加：
   - `-com.apple.CoreData.SQLDebug 1`
   - `-com.apple.CoreData.Logging.stderr 1`

### 2. コンソールログの確認
アプリを実行して録音を保存する際に、Xcodeのコンソールに表示される詳細エラーを確認してください。

### 3. 確認するポイント
- エラーコード
- エラードメイン
- Validation Errorsの詳細
- 具体的にどのフィールドでエラーが発生しているか

### 4. よくある原因
1. **必須フィールドがnil**
   - id, createdAt, durationが設定されていない
   
2. **文字列の長さ制限**
   - titleやfilePathが長すぎる可能性
   
3. **ファイルパスの形式**
   - filePathが無効な形式になっている
   
4. **重複するID**
   - 同じUUIDが既に存在する

### 5. 現在の実装での対策
RecordingView.swiftに以下のデバッグコードを追加しました：
- 詳細なエラー情報の取得
- 各フィールドの値の出力
- NSErrorからの詳細情報抽出

### 6. 次のステップ
1. アプリを実行して録音を試す
2. コンソールに表示されるエラー詳細を確認
3. 具体的なエラー内容を教えてください

## 一時的な回避策
エラーが続く場合は、以下を試してください：

1. アプリを削除して再インストール
2. シミュレーターの場合：Device → Erase All Content and Settings
3. Core Dataモデルの再生成