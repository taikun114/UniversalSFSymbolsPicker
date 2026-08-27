# UniversalSFSymbolsPicker 変更ログ
[English](../CHANGELOG.md) | **日本語**

<!--
記載する順番は以下の通り。
- UniversalSFSymbolsPicker
  - 新機能
  - バグ修正と改善
- UniversalSFSymbolsPicker Demo
  - 新機能
  - バグ修正と改善

それぞれの項目には以下の順番で記載する。
- 特筆すべき情報
- 対応
- 追加
- 修正
- 改善
- 変更
- 削除

注意点
- リストの一層目は太字にすること
- リンクは太字にすること
- IssueやPull Request、Discussionへのリンクを貼る場合は完全なURLを記載すること
-->

## 1.0.2
### UniversalSFSymbolsPicker
#### バグ修正と改善
- **iOS / iPadOSのシートがダークモード時にわずかにグリーンに見える問題を修正**
- **バージョン26以降で検索欄の見た目を改善**
- **iOS / iPadOS 27およびmacOS Golden Gateのスクロールエッジエフェクトを改善**
  - OS側の修正により正しく表示されるようになったため、`.soft`スタイルに戻しました。

### UniversalSFSymbolsPicker Demo
#### バグ修正と改善
- **macOS Golden Gateでメインウィンドウのコンテンツがはみ出る問題を修正**
- **メインウィンドウが閉じられたときにアプリが終了されるように改善**

## 1.0.1
### UniversalSFSymbolsPicker
#### バグ修正と改善
- **macOS Golden Gateのカテゴリピッカー内でカテゴリアイコンが表示されなかった問題を修正**
- **iOS / iPadOS 27およびmacOS Golden Gateでスクロールエッジエフェクトが表示されなかった問題を修正**
  - `.hard`スタイルを明示的に指定して、システムのデフォルトの見た目が反映されるようにしました。

### UniversalSFSymbolsPicker Demo
#### バグ修正と改善
- **iOS / iPadOS 26以降のコンパクトモードでポップオーバーを開いたときにスクロールエッジエフェクトが表示されない問題を修正**
