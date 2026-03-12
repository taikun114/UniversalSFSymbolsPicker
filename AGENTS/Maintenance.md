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

`SFSymbolService` では、膨大な SF Symbols の中から特定の言語・地域固有のバリエーション（例: `.ar`, `.hi`, `.ja`, `.sat`, `.rtl`）を除外するために、明示的なリストに基づいた動的フィルタリングロジックを採用しています。

**ロジック:** シンボル名をドット（`.`）で分割し、その要素が `symbolVariants` セットに含まれる場合に、多言語・地域版のバリアントと見なして除外する。

ユーザーから「ロケールフィルタリングがきちんと動作しているか確認して」と聞かれた場合は次のようにして対処できます。

### 1. 現状のチェック (スキャン)
新しいバージョンの SF Symbols データを導入した際などは、以下のコマンドで 2 文字および 3 文字の要素を抽出し、出現頻度を確認してください。

```bash
# 2文字の要素をスキャン
grep -oE "\.[a-z]{2}[\.\"]" Sources/UniversalSFSymbolsPicker/Resources/SFSymbolData.json | sort | uniq -c | sort -nr

# 3文字の要素をスキャン
grep -oE "\.[a-z]{3}[\.\"]" Sources/UniversalSFSymbolsPicker/Resources/SFSymbolData.json | sort | uniq -c | sort -nr
```

### 2. 漏れているロケールコードの特定と修正
抽出されたリストの中に、**「明らかに特定の言語や地域向けのバリエーションなのに、まだ除外対象に含まれていないコード」** がないか確認します。

新たなロケールコード（例: 将来追加される 3 文字の言語コードなど）が見つかった場合は、`Sources/UniversalSFSymbolsPicker/SFSymbolService.swift` 内の `symbolVariants` セットにそのコードを追加してください。

```swift
// SFSymbolService.swift 内の定義
let symbolVariants: Set<String> = [
    "ar", "hi", "ja", ...,
    "rtl", "sat", "mni",
    "xyz" // 新たに見つかったコードを追加
]
```

### 3. フィルタリング精度の検証
現在の `symbolVariants` リストを適用した状態で、残りの要素がすべて正しく汎用的な単語であることを確認します。

```bash
# 除外スキャン（例：2文字の場合。symbolVariantsに含まれるものをgrep -vで除外して確認）
grep -oE "\.[a-z]{2}[\.\"]" Sources/UniversalSFSymbolsPicker/Resources/SFSymbolData.json | grep -vE "\.(ar|hi|he|zh|th|ja|ko|el|ru|my|km|bn|gu|kn|ml|mr|or|pa|si|ta|te)[\.\"]" | sort | uniq -c | sort -nr
```

出力結果に言語コードが含まれておらず、`up`, `on`, `tv` などの汎用単語だけであれば、フィルタリングは適切に機能しています。

## パッケージローカライズのメンテナンス

`Localizable.xcstrings` に新しい言語を追加したり、既存の翻訳を更新したりする場合は、可能な限り Apple の **SF Symbols アプリ** に含まれる公式の翻訳に合わせるため、スクリプトを作成する前に公式の翻訳データを参照する必要があります。

ユーザーから「パッケージのローカライズに新しい言語を追加して」と聞かれた場合は次のようにして対処できます（このセクションはあくまでパッケージローカライズの話であり、デモアプリのローカライズとは異なります）。

### 1. 公式翻訳データの抽出方法

SF Symbols アプリ内のフレームワークには、サイドバーで使用されているカテゴリ名（システムカテゴリ）の翻訳ファイルが含まれています。以下のコマンドを使用して、特定の言語の翻訳一覧を確認できます。

```bash
# 例: 日本語 (ja) の翻訳を抽出する場合
plutil -p "/Applications/SF Symbols.app/Contents/Frameworks/SFSymbolsShared.framework/Versions/A/Resources/ja.lproj/CategoryTitles.strings"
```

※ アプリのパスが異なる場合は、実際のパスに合わせて調整してください。

### 2. 主要な翻訳キーの一覧

以下のキーが `Localizable.xcstrings` で管理されています。カテゴリ名は `CategoryTitles.strings` の値と一致させる必要があります。

- **システムカテゴリ:** `Accessibility`, `All`, `Arrows`, `Automotive`, `Camera & Photos`, `Commerce`, `Communication`, `Connectivity`, `Devices`, `Editing`, `Fitness`, `Gaming`, `Health`, `Home`, `Human`, `Indices`, `Keyboard`, `Maps`, `Math`, `Media`, `Nature`, `Objects & Tools`, `Privacy & Security`, `Shapes`, `Text Formatting`, `Time`, `Transportation`, `Weather`
- **UI 文字列:** `All Symbols`, `Category`, `Category: %@`, `Custom Categories`, `Search Icons...`, `Select an Icon`, `System Categories`, `Cancel`, `Done`

### 3. 翻訳更新用スクリプトのサンプル

新しい言語を追加する際は、以下の Python スクリプトをテンプレートとして使用すると、既存の JSON 構造を壊さずに安全に更新できます。

```python
import json

# 1. 翻訳データの定義
# lang_code: "ja" (日本語) など
lang_code = "ja"
translations = {
    "Accessibility": "アクセシビリティ",
    "All": "すべて",
    # ... (抽出したデータをここに記載)
    "Search Icons...": "アイコンを検索…",
    "Cancel": "キャンセル",
    "Done": "完了"
}

file_path = 'Sources/UniversalSFSymbolsPicker/Resources/Localizable.xcstrings'

# 2. ファイルの読み込みと更新
with open(file_path, 'r') as f:
    data = json.load(f)

for key, value in translations.items():
    if key in data['strings']:
        # 'localizations' キーがない場合や、辞書でない場合を考慮して初期化
        if 'localizations' not in data['strings'][key] or not isinstance(data['strings'][key]['localizations'], dict):
            data['strings'][key]['localizations'] = {}

        data['strings'][key]['localizations'][lang_code] = {
            "stringUnit": {"state": "translated", "value": value}
        }

# 3. 書き出し
with open(file_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
```



