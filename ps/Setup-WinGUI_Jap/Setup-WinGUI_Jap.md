# Set-JapanLocale.ps1

## 概要

このスクリプトは、Windows Server 2019 / 2022 / vNext (Desktop Experience) 環境において、
Windowsのシステムロケール、表示言語、カルチャ、地域設定、キーボードレイアウト、IME、タイムゾーンを日本仕様 (ja-JP) に自動構成するものです。
管理者権限で実行し、完了後はシステムの再起動が必要です。

---

## 特徴

- 日本語言語パックのインストール（未インストール時のみ）
- システムロケール、カルチャ、表示言語を日本語 (ja-JP) に設定
- ユーザー言語リストを日本語IMEキーボードで構成
- タイムゾーンを「Tokyo Standard Time」に設定
- BCD設定を日本語ロケールに統一（起動時表示用）
- 冪等性（再実行しても問題なし）

---

## 動作対象

- Windows Server 2019 (Desktop Experience)
- Windows Server 2022
- Windows Server vNext (最新ビルド)

※Coreエディションは対象外

---

## 実行方法

1. PowerShellを【管理者権限】で起動します。
2. 以下コマンドでスクリプトを実行します。

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Set-JapanLocale.ps1
```

3. 実行完了後、必ずシステムを【再起動】してください。

---

## スクリプト内容概要

| 機能                     | 詳細                                      |
|---------------------------|-------------------------------------------|
| 言語パックインストール    | ja-JPのLanguage.Basic、Handwritingなど   |
| システムロケール設定      | Set-WinSystemLocale, Set-Culture           |
| 表示言語設定 (UI)         | Set-WinUILanguageOverride, レジストリ設定 |
| ユーザー言語リスト構成    | New-WinUserLanguageList + IME設定          |
| タイムゾーン設定           | Tokyo Standard Time                       |
| BCDロケール設定           | bcdeditで{current}と{bootmgr}に設定        |

---

## 注意事項

- スクリプト実行にはインターネット接続が必要です（言語パックダウンロード時）。
- スクリプト実行後、必ず【再起動】してください（設定反映のため）。
- 言語パックのインストールに数分かかる場合があります。途中で中断しないでください。

---

## ライセンス

本スクリプトはMITライセンスに基づき提供されています。商用・非商用問わず自由に利用・改変可能です。