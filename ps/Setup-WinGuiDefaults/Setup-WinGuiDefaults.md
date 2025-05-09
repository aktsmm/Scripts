# Setup-WinGuiDefaultSetting.ps1

## 概要
『Setup-WinGuiDefaultSetting.ps1』は、Windows Server 2019 / Windows 10以降のGUI環境向けの初期セットアップを簡単に自動化するためのPowerShellスクリプトです。管理者が新規構築や定期的なメンテナンス時に利用できます。

---

## 実行環境
- Windows Server 2019 以降
- Windows 10 以降
- 管理者権限での実行が必要

---

## セットアップ内容
このスクリプトは以下の操作を自動で行います。

### 1. タスクバーへのアプリのピン留め
以下のアプリケーションをタスクバーにピン留めします（既にピン留め済みの場合はスキップされます）。
- メモ帳（Notepad）
- Windows PowerShell

### 2. エクスプローラー設定の変更
ファイルエクスプローラーの利便性向上のために、以下の設定を適用します。
- 隠しファイルを表示
- 保護されたOSファイルを表示
- ファイルの拡張子を表示

設定適用後、エクスプローラーが自動的に再起動され、変更が即時反映されます。

### 3. Internet Explorer Enhanced Security Configuration (IE ESC) の無効化
IE ESCを無効にし、管理者および通常ユーザー両方に設定を反映します。変更を完全に反映させるには、実行後に再ログインが必要です。

---

## 実行方法
PowerShellを管理者権限で起動し、以下のコマンドを実行してください。

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Setup-WinGuiDefaultSetting.ps1
```

---

## 備考
- スクリプトは冪等性を備えているため、何度でも安全に実行可能です。
- 変更後に即座に反映されない場合、システムの再ログインや再起動を推奨します。

---

## 注意事項
設定内容を理解した上で自己責任にて実行してください。環境によっては予期しない挙動が生じる可能性があります。

---

## ライセンス
本スクリプトはMITライセンスで提供されています。