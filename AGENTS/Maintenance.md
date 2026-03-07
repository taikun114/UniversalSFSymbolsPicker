# プロジェクトのメンテナンス方法

## 最新のSF Symbolsに更新する

対応しているSF Symbolsのリストは`SFSymbolData.json`で指定されています。このファイルはスクリプトによって自動生成されたものであるため、手動で変更すべきではありません。

新たなバージョンのSF Symbolsがリリースされた際は、スクリプトを使うことで新しいアイコンに対応することができます。ユーザーから「新しいバージョンのSF Symbolsに対応して」と言われた場合は次の方法で対処できます。

新しいアイコンに対応するためのスクリプトを実行するには、最初に次の条件を満たしている必要があります。

- Macを使用していること
  - macOSのシステムファイルから制限付きアイコンのリストを取得するため、macOS以外を搭載するコンピューターでは使用できません。
- 最新の[SF Symbols](https://developer.apple.com/sf-symbols/)アプリがインストールされていること
  - アプリケーションの場所は問いません。
- Python 3がインストールされていること

最新のアイコンデータを抽出するために、`extract_metadata.py`ツールを使用します。

```bash
python3 Utilities/extract_metadata.py
```

SF Symbolsアプリがアプリケーションフォルダ（`/Applications`）以外の場所にインストールされている場合は、`--path`または`-p`オプションをつけてアプリケーションへのパスを指定して実行する必要があります。

パスは次のような形式に対応しています。

- `/Applications/SF\ Symbols.app`のようなアプリ自体へのパス
- `/Applications/SF\ Symbols.app/Contents/Resources/Metadata`のようなメタデータフォルダへのパス

## SF Symbols ロケールフィルタリングのメンテナンス

`SFSymbolService` では、膨大な SF Symbols の中から特定の言語・地域固有のバリエーション（例: `.ar`, `.hi`, `.ja`）を除外するために、以下の動的フィルタリングロジックを採用しています。

**ロジック:** シンボル名をドット（`.`）で分割し、要素が 2 文字であればロケールコードと見なして除外する。ただし、意味のある一般的な単語（例: `up`, `tv`, `ac`）はホワイトリストで許可する。

ユーザーから「ロケールフィルタリングがきちんと動作しているか確認して」と聞かれた場合は次のようにして対処できます。

### 1. 現状のチェック (スキャン)
新しいバージョンの SF Symbols データを導入した際などは、以下のコマンドで 2 文字の要素を抽出し、出現頻度を確認してください。

```bash
grep -oE "\.[a-z]{2}[\.\"]" Sources/UniversalSFSymbolsPicker/Resources/SFSymbolData.json | sort | uniq -c
```

### 2. 誤判定の特定と修正
抽出されたリストの中に、**「本来表示されるべきなのに、2文字であるために除外されてしまっている単語」** がないか確認します。

誤判定（本来は表示したい 2 文字単語）が見つかった場合は、`Sources/UniversalSFSymbolsPicker/SFSymbolService.swift` 内の `nonLocaleTwoLetterWords` セットにその単語を追加してください。

```swift
// SFSymbolService.swift 内のホワイトリスト
let nonLocaleTwoLetterWords: Set<String> = [
    "up", "on", "go", "tv", "pc", "3d", "ex", "of", "to", "in", "by", "at", "as",
    "ac", "dc", "lc", "or", "no", "re", "pi",
    "ai" // 例: 将来 .ai という要素を持つ汎用アイコンが登場した場合に追加する
]
```

### 3. フィルタリング精度の検証
現在のホワイトリストを適用した状態で、残りの 2 文字要素がすべて正しくロケールコードであることを確認します。

```bash
# 現在のホワイトリスト単語をパイプ | で繋いで除外スキャンを実行
grep -oE "\.[a-z]{2}[\.\"]" Sources/UniversalSFSymbolsPicker/Resources/SFSymbolData.json | grep -vE "\.(up|on|go|tv|pc|3d|ex|of|to|in|by|at|as|ac|dc|lc|or|no|re|pi)[\.\"]" | sort | uniq -c
```

出力結果がすべて `.ar`, `.he`, `.zh` などの言語コードだけであれば、フィルタリングは適切に機能しています。
