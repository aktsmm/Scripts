# Screen2text OCR

画面上の指定領域を連続してOCR（光学文字認識）し、テキストファイルに出力するPythonツールです。

## 概要

このツールは、ユーザーが画面上で選択した領域を連続してスクリーンショット撮影し、OCRを使用してテキストを抽出します。電子書籍や文書の連続ページを自動的にテキスト化する際に便利です。

**環境に応じた2つのバージョンを提供：**
- **オンライン環境**: EasyOCR版（高精度・簡単セットアップ）
- **オフライン環境**: Tesseract版（完全オフライン・軽量）

## バージョン

- **Screen2text_ocr.py**: Tesseract-OCRを使用したバージョン
- **Screen2text_ocr2.py**: EasyOCRを使用したバージョン（一時ファイル自動削除・推奨）

## 機能

- 画面領域の選択（マウスカーソルによる範囲指定）
- 選択領域の確認機能
- 複数ページの自動OCR処理
- 日本語・英語テキストの認識
- テキストファイルへの自動出力
- 自動ページ送り機能（右キー押下）
- 一時画像ファイルの管理
  - Screen2text_ocr.py: 単一ファイル（temp.png）を使用
  - Screen2text_ocr2.py: 各ページ個別保存（自動削除）

## 必要な環境

- Python 3.6以上

### Screen2text_ocr.py（Tesseract版）の場合
- Tesseract-OCR（C:\Program Files\Tesseract-OCR\tesseract.exeにインストール済み）

### Screen2text_ocr2.py（EasyOCR版）の場合

- インターネット接続（初回実行時にモデルダウンロードのため）

## 必要なライブラリ

### Screen2text_ocr.py（Tesseract版）

```bash
pip install pyautogui pytesseract pillow
```

### Screen2text_ocr2.py（EasyOCR版）- 推奨

```bash
pip install pyautogui easyocr pillow
```

## 事前準備

### Screen2text_ocr.py（Tesseract版）を使用する場合

#### Tesseract-OCRのインストール

1. [Tesseract-OCR](https://github.com/UB-Mannheim/tesseract/wiki)から最新版をダウンロード
2. `C:\Program Files\Tesseract-OCR\`にインストール
3. 日本語言語パック（jpn.traineddata）が含まれていることを確認

#### 日本語言語パックの追加（必要な場合）

```bash
# tessdata フォルダに jpn.traineddata をダウンロード
# https://github.com/tesseract-ocr/tessdata/raw/main/jpn.traineddata
```

### Screen2text_ocr2.py（EasyOCR版）を使用する場合

- 特別な事前準備は不要です
- 初回実行時に自動的に日本語・英語モデルがダウンロードされます
- インターネット接続が必要です

## 使用方法

### Tesseract版の場合

```bash
python Screen2text_ocr.py
```

### EasyOCR版の場合（推奨）

```bash
python Screen2text_ocr2.py
```

### 操作手順（両バージョン共通）

1. 画面領域の指定：
   - 「5秒以内にキャプチャ範囲の左上角にマウスを移動してください...」→ 左上角にマウス移動
   - 「次に5秒以内に右下角にマウスを移動してください...」→ 右下角にマウス移動

1. 範囲の確認：
   - 表示された範囲で良ければEnterキーを押下
   - やり直す場合は「N」を入力

1. 設定の入力：
   - OCRするページ数を入力（例：10）
   - 出力ファイル名を入力（例：output.txt、未入力の場合はoutput.txt）

1. ウィンドウのアクティブ化：
   - 「5秒以内にウィンドウをクリックしてアクティブにしてください...」→ 対象ウィンドウをクリック

1. 自動処理開始：
   - 指定されたページ数分、自動的にOCR処理が実行されます
   - 各ページ処理後、自動的に右キーが押下されます

## 出力例

```text
5秒以内にキャプチャ範囲の左上角にマウスを移動してください...
左上: (100, 50)
次に5秒以内に右下角にマウスを移動してください...
右下: (500, 300)
キャプチャ範囲: (100, 50, 400, 250)
この範囲でよければEnter。やり直す場合は'N'を入力: 
OCRするページ数を入力してください（例: 10）: 5
出力ファイル名を入力してください（例: output.txt）: document.txt
5秒以内にウィンドウをクリックしてアクティブにしてください...
Page 1 OCR完了
Page 2 OCR完了
Page 3 OCR完了
Page 4 OCR完了
Page 5 OCR完了
全ページ処理が完了しました！
```

## 出力ファイル形式

```text
--- page 1 ---
認識されたテキスト内容
（ページ1の内容）

--- page 2 ---
認識されたテキスト内容
（ページ2の内容）

...
```

## 使用例

### 一般的な用途
- 電子書籍のテキスト抽出
- PDFビューワーからのテキスト抽出
- Webページの連続スクリーンショットのテキスト化
- プレゼンテーション資料のテキスト化

### 環境別の推奨用途

#### オンライン環境（EasyOCR版推奨）
- **学術研究**: 高精度が要求される論文や資料のデジタル化
- **ビジネス文書**: 多言語混在の企業資料のテキスト化
- **品質重視**: 認識精度を最優先する用途

#### オフライン環境（Tesseract版推奨）
- **機密文書**: セキュリティが重要な社内資料の処理
- **組み込みシステム**: ネットワーク接続のない環境での自動化
- **リソース制約**: メモリやストレージが限られた環境

## 注意事項

### 環境要件

#### オンライン環境でEasyOCR版を使用する場合
- **初回のみ**: モデルダウンロードで数GBの通信が発生
- **継続使用**: インターネット接続は不要（モデル保存後）
- **メモリ**: GPU使用時は十分なVRAMが必要

#### オフライン環境でTesseract版を使用する場合
- **事前準備**: Tesseract-OCRのインストールが必須
- **完全オフライン**: 一度セットアップすれば外部通信不要
- **セキュリティ**: 外部通信なしでプライベート文書を処理可能

### 共通事項

- 座標はピクセル単位で表示されます
- 処理中は対象ウィンドウがアクティブである必要があります
- ページ送りは右キーの押下で行われます

### Tesseract版（Screen2text_ocr.py）

- Tesseract-OCRが正しくインストールされている必要があります
- 日本語テキストの認識精度は画像の品質に依存します
- 一時ファイル（temp.png）が作成されます

### EasyOCR版（Screen2text_ocr2.py）

- 初回実行時にモデルのダウンロードが発生します（数GB）
- 一時画像ファイル（temp_0.png, temp_1.png...）が作成されますが、処理後自動的に削除されます
- ページ切り替えの待機時間が1.5秒設定されています
- Tesseract版より一般的に認識精度が高いです
- ディスク容量を節約できます（一時ファイル自動削除）

## トラブルシューティング

### Tesseract版のトラブルシューティング

#### Tesseractが見つからない場合

- Tesseract-OCRのインストールパスを確認してください
- スクリプト内のpytesseract.pytesseract.tesseract_cmdのパスを環境に合わせて変更してください

### EasyOCR版のトラブルシューティング

#### 初回実行が遅い場合

- 初回実行時にモデルのダウンロードが行われるため時間がかかります
- インターネット接続を確認してください

#### メモリ不足エラーが発生する場合

- EasyOCRはGPUを使用するためメモリ使用量が多くなります
- 他のアプリケーションを終了してメモリを確保してください

### 共通のトラブルシューティング

#### OCR精度が低い場合

- キャプチャ範囲を調整してください
- 画面の解像度やズーム率を調整してください
- テキストのコントラストを改善してください

## どちらのバージョンを選ぶべきか

### 環境別の推奨バージョン

#### オンライン環境（インターネット接続あり）
**EasyOCR版（Screen2text_ocr2.py）を強く推奨**

- **簡単なセットアップ**: 複雑なTesseractのインストールが不要
- **高い認識精度**: 特に日本語テキストの認識精度が優秀
- **自動言語検出**: 日本語・英語の混在テキストも適切に処理
- **GPU加速**: 利用可能な場合はGPUを使用して高速処理
- **自動クリーンアップ**: 一時ファイルを自動削除してディスク容量を節約
- **安定性**: 処理中に中断されても一時ファイルが残りにくい

#### オフライン環境（インターネット接続なし）
**Tesseract版（Screen2text_ocr.py）を推奨**

- **オフライン完結**: 初回実行時にダウンロードが不要
- **軽量**: メモリ使用量が少ない
- **カスタマイズ可能**: Tesseractの詳細設定が可能
- **安定した動作**: ネットワーク接続に依存しない

### 特殊な用途での選択

#### EasyOCR版を選ぶべき場合
- **高精度が必要**: 文字認識の精度を最優先する場合
- **多言語混在テキスト**: 日本語・英語が混在している文書
- **GPU環境**: 高性能なGPUが利用可能な環境

#### Tesseract版を選ぶべき場合
- **セキュリティ重視**: 外部通信を避けたい環境
- **リソース制約**: メモリやストレージが限られた環境
- **組み込み用途**: システムに組み込んで使用する場合

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 作成者

yamapan