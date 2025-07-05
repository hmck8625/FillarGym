# FillarGym

<p align="center">
  <img src="docs/assets/logo.png" alt="FillarGym Logo" width="200"/>
</p>

<p align="center">
  <strong>AI音声分析で「えー」「あー」を撲滅</strong><br>
  話し方のプロフェッショナルへと変身するiOSアプリ
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-blue.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Xcode-15.0%2B-blue.svg" alt="Xcode 15.0+">
</p>

## 📱 概要

FillarGymは、音声録音からフィラー語（「えー」「あー」「その」など）を検出・分析し、話し方の改善を支援するiOSアプリです。OpenAIの最新技術を活用して、誰でも簡単に説得力のある話し方を身につけることができます。

### 主な特徴

- 🎤 **簡単録音**: ワンタップで高品質録音
- 🤖 **AI分析**: OpenAI Whisper & GPT-4による高精度分析
- 📊 **詳細レポート**: フィラー語の種類・回数・位置を可視化
- 📈 **進捗追跡**: 改善度を数値で確認
- 🔒 **プライバシー重視**: 音声データは100%ローカル保存

## 🚀 クイックスタート

### 必要な環境

- macOS Sonoma以降
- Xcode 15.0以降
- iOS 17.0以降のデバイスまたはシミュレータ
- OpenAI API キー（実際の分析機能を使用する場合）

### セットアップ手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/hmck8625/FillarGym.git
cd FillarGym

# 2. CocoaPodsをインストール（初回のみ）
pod install

# 3. Xcodeでプロジェクトを開く
open FillarGym.xcworkspace

# 4. OpenAI APIキーを設定（オプション）
# Xcode → Product → Scheme → Edit Scheme...
# Run → Arguments → Environment Variables
# OPENAI_API_KEY = your-api-key-here
```

詳細なセットアップ手順は [docs/setup/QUICK_START.md](docs/setup/QUICK_START.md) を参照してください。

## 📚 ドキュメント

- [セットアップガイド](docs/setup/) - 環境構築・API設定
- [開発ガイド](docs/development/) - デバッグ・エラー対処法
- [デプロイガイド](docs/deployment/) - App Store申請手順
- [マーケティング資料](docs/marketing/) - プライバシーポリシー・プロモーション文

## 🏗 アーキテクチャ

```
FillarGym/
├── FillarGym/          # メインアプリケーション
│   ├── Models/         # Core Dataモデル
│   ├── Views/          # SwiftUI ビュー
│   ├── Services/       # ビジネスロジック
│   └── Resources/      # アセット・設定ファイル
├── FillarGymTests/     # ユニットテスト
├── FillarGymUITests/   # UIテスト
└── docs/               # ドキュメント
```

### 技術スタック

- **UI**: SwiftUI
- **データベース**: Core Data
- **音声処理**: AVFoundation
- **AI分析**: OpenAI API (Whisper + GPT-4)
- **Analytics**: Firebase Analytics
- **セキュリティ**: Keychain Services

## 🤝 コントリビューション

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 📧 お問い合わせ

- 開発者: [hmck8625](https://github.com/hmck8625)
- Email: support@fillargym.com
- Issues: [GitHub Issues](https://github.com/hmck8625/FillarGym/issues)

---

<p align="center">
  Made with ❤️ by FillarGym Team
</p>