# OpenAI API セットアップガイド

## 実装内容

OpenAI API統合を実装しました。以下の機能が追加されています：

### 1. APIキー管理
- **KeychainManager.swift**: APIキーを安全にKeychainに保存
- **APIKeySettingsView.swift**: 設定画面からAPIキーを設定・検証

### 2. OpenAI API統合
- **Whisper API**: 音声ファイルを文字起こし
- **GPT-4 API**: 文字起こし結果からフィラー語を検出・分析

### 3. 分析フロー
1. 録音完了後、音声ファイルをWhisper APIに送信
2. 文字起こし結果をGPT-4で分析
3. フィラー語の検出と改善提案を生成
4. 結果をCore Dataに保存

## セットアップ手順

### 1. OpenAI APIキーの取得
1. [OpenAI Platform](https://platform.openai.com/api-keys)にアクセス
2. アカウントを作成またはログイン
3. 「Create new secret key」をクリック
4. APIキー（sk-で始まる文字列）をコピー

### 2. アプリでの設定
1. アプリを起動
2. 設定タブ → API設定 → OpenAI APIキーをタップ
3. 取得したAPIキーを入力
4. 「保存して検証」をタップ

### 3. 使用方法
- APIキーが設定されている場合：実際の音声分析を実行
- APIキーが未設定の場合：モック分析を実行（テスト用）

## 料金の目安
- Whisper API: $0.006/分
- GPT-4 API: ~$0.01/分析
- 月100回の分析で約$1-2程度

## トラブルシューティング

### APIキーが無効と表示される
- キーが正しくコピーされているか確認（sk-で始まる）
- OpenAI アカウントに課金設定が完了しているか確認
- APIの使用制限に達していないか確認

### 分析が失敗する
- ネットワーク接続を確認
- 音声ファイルのサイズが大きすぎないか確認（10分以内推奨）
- APIキーが正しく設定されているか確認

## 開発者向け情報

### 環境変数での設定（開発時）
Xcodeで開発する場合、環境変数でAPIキーを設定できます：
1. Xcode → Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. `OPENAI_API_KEY` を追加して値を設定

### モック分析
APIキーがない場合でも、モック分析でアプリの動作をテストできます。
モック分析では以下のようなダミーデータが生成されます：
- フィラー語数: 3-15個（ランダム）
- フィラー率: 2.0-8.0/分（ランダム）
- 発話速度: 120-180語/分（ランダム）