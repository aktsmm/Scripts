# AiChat (PowerShell)

## 概要

このフォルダーには、Azure Functions の HTTP エンドポイントを呼び出して AI 応答を取得する 2 つの PowerShell スクリプトが含まれます。

- chatps_CLI.ps1: コマンドラインで使う最小 CLI。関数 `ai` を提供し、与えたメッセージを 1 回のリクエストとして送信します（ステートレス）。
- chatps.ps1: Windows Forms を使った GUI クライアント。入力欄・送信/クリアボタン付き（こちらもステートレス）。

両者とも共通して、HTTP POST の JSON ボディを Azure Functions に送り、応答 JSON の `reply` プロパティを表示します。履歴は送信しないため、毎回の発話は独立です（サーバー側で文脈保持をしていない限り、会話履歴は渡されません）。

## 共通の前提・仕様

- 送信先 URL: 変数 `$url` に `https://<your-func>.azurewebsites.net/api/<function>?code=<function_key>` の形式を設定します。
  - chatps_CLI.ps1: ファイル先頭に `$url = '<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>'` があり、ここを書き換えるか、読み込み後に `$url` を上書きしてください。
  - chatps.ps1: `$url` がプレースホルダーのままなら、起動時に URL 入力ダイアログが出ます。
- リクエスト（サーバーへ送るボディ）
  - JSON: `{ "messages": [ { "role": "user", "content": "..." } ] }`
- レスポンス（サーバーからの返り値）
  - 想定: JSON に `reply` 文字列プロパティがあること。なければ受信 JSON 全体を表示します。
- タイムアウト: 30 秒（Invoke-RestMethod の `-TimeoutSec 30`）。
- エラー処理: 例外時は `エラー: <メッセージ>` を表示します。

### API 契約（最小）

- Request

```json
{
  "messages": [{ "role": "user", "content": "こんにちは" }]
}
```

- Response（推奨）

```json
{
  "reply": "こんにちは！ご用件は何でしょう？"
}
```

`reply` がない場合は受信 JSON 全体を文字列化して返します。

## chatps_CLI.ps1（CLI 版, 履歴なし）

- 提供機能: 関数 `ai`。
- 使い方（例）

```powershell
# 実行ポリシーを一時緩和（必要な場合）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# スクリプトを読み込む（ドットソース）
. .\chatps_CLI.ps1

# 送信先URLをセッションで上書きしたい場合
$url = 'https://<your-func>.azurewebsites.net/api/<function>?code=<function_key>'

# 単発で質問を送る（可変長引数を空白結合して送信）
ai "こんにちは"

# 複数語もOK（スペースで結合されて1メッセージになります）
ai 仕様 質問 です
```

- 振る舞いの要点
  - ステートレス（毎回のメッセージのみを送信）。
  - 応答は `reply` があればそれを表示。なければ受信 JSON を表示。
  - タイムアウト 30 秒。例外は `エラー: ...` と表示。

## chatps.ps1（GUI 版, 履歴なし）

- 提供機能: Windows Forms による簡易チャット UI。
  - テキスト入力、送信ボタン、クリアボタン、Enter キー送信。
  - 送信直後に「AI おじ: 考え中...」と表示し、応答受信で置き換えます。
  - 表示フォントに "BIZ UDP ゴシック" を指定しています（未インストール環境では既定フォントにフォールバックします）。
- 使い方（例）

```powershell
# 実行ポリシーを一時緩和（必要な場合）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# そのまま実行（URLが未設定なら起動時に入力ダイアログが出ます）
.\chatps.ps1

# 事前にURLを埋め込んで使いたい場合は、ファイル先頭の $url を書き換えて保存
```

- 振る舞いの要点
  - ステートレス（入力テキストのみを送信）。
  - 応答は `reply` を優先表示。なければ受信 JSON 全体を表示。
  - 送信/クリアボタンにホバー時の色変化あり。

## 必要環境

- Windows
- PowerShell 7.0 以降（`??`（Null 合体演算子）を使用しているため、Windows PowerShell 5.1 では動作しません）
- インターネット接続（Azure Functions への到達が必要）

## トラブルシューティングのヒント

- 401/403: Function の `code` が誤っている/権限不足。ポータルで関数キーを再確認してください。
- タイムアウト（30 秒）: Function 側の処理が遅延。Function のログやスケール設定を確認してください。
- ネットワーク/プロキシ: 企業ネットワークではプロキシ設定が必要な場合があります。`Invoke-RestMethod` の既定プロキシや `-Proxy` オプション検討。

## ライセンス

このリポジトリ配下の `Scripts/ps/AiChat` フォルダーの内容は MIT ライセンスで提供します。必要に応じて上位の LICENSE/README と整合を取ってください。

- 参考: [MIT License (Open Source Initiative)](https://opensource.org/license/mit)
- 簡易表記:
  - Copyright (c) 著作権者
  - 本ソフトウェアおよび関連文書ファイル（以下「ソフトウェア」）の複製を取得する者に対し、ソフトウェアを無制限に扱うことを許可します（使用、複製、改変、結合、公開、配布、サブライセンス、および/または販売を含む）。
  - 上記の著作権表示および本許諾表示をソフトウェアのすべての複製または重要な部分に記載するものとします。
  - 本ソフトウェアは「現状のまま」提供され、明示黙示を問わずいかなる保証も伴いません。
