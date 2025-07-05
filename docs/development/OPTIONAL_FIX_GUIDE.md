# Optional値の修正ガイド

## 問題の原因

Core Dataでは、すべての属性がデフォルトでOptionalになっています。これが多くのOptionalエラーの原因です。

## 解決方法

### 1. 拡張プロパティを使用（推奨）

`FillerAnalysis+Extensions.swift`に追加済み：

```swift
// analysisDateを常に非nilとして扱うための計算プロパティ
var safeAnalysisDate: Date {
    return analysisDate ?? Date()
}
```

### 2. 使用箇所での修正パターン

#### パターンA: nil合体演算子を使用
```swift
// 修正前
analysis.analysisDate

// 修正後
analysis.analysisDate ?? Date()
```

#### パターンB: guard文を使用
```swift
guard let date = analysis.analysisDate else { return }
```

#### パターンC: if letを使用
```swift
if let date = analysis.analysisDate {
    // dateを使用
}
```

### 3. Core Dataモデルの設定

Xcodeで以下を設定することでOptionalを回避：

1. Core Dataモデルエディタを開く
2. 属性を選択
3. Data Model Inspectorで「Optional」のチェックを外す
4. デフォルト値を設定

## 今後の開発指針

1. 新しいCore Data属性は必要に応じて「Optional」を外す
2. 日付や数値は適切なデフォルト値を設定
3. UI表示時は常にnilチェックを行う
4. 計算プロパティで安全なアクセスを提供