
# AutoSSHWatchdog.ps1

## ✅ 結論（TL;DR）
**AutoSSHWatchdog.ps1** は **SSH セッションを常時監視** し、切断時に **自動再接続** する PowerShell スクリプトです。  
30 秒以上続いたセッションを「確立済み」とみなし、異常終了した場合は **最大 3 回** まで再接続。  
運用監視・メンテナンス検知・長時間バッチ処理などで「接続が落ちても張り直してほしい」状況に最適です。

---

## 目次
- [AutoSSHWatchdog.ps1](#autosshwatchdogps1)
  - [✅ 結論（TL;DR）](#-結論tldr)
  - [目次](#目次)
  - [特長](#特長)
  - [前提条件](#前提条件)
  - [インストール](#インストール)
  - [クイックスタート](#クイックスタート)
  - [パラメータ一覧](#パラメータ一覧)
  - [動作フロー](#動作フロー)
  - [ログレベル](#ログレベル)
  - [カスタマイズ例](#カスタマイズ例)
    - [① 再接続回数を 10 回に変更](#-再接続回数を-10-回に変更)
    - [② 監視対象コマンドをリモート実行](#-監視対象コマンドをリモート実行)
    - [③ ログをファイルにも保存](#-ログをファイルにも保存)
  - [トラブルシューティング](#トラブルシューティング)
  - [実務での利用例](#実務での利用例)
  - [付録](#付録)
  - [パスワードレスSSH](#パスワードレスssh)
    - [Windows で鍵ペアを生成](#windows-で鍵ペアを生成)
    - [公開鍵を Ubuntu に登録](#公開鍵を-ubuntu-に登録)
  - [ライセンス](#ライセンス)

---

## 特長
| 機能 | 説明 |
|------|------|
| **自動再接続** | 切断を検知すると指定回数まで即座に再接続 |
| **しきい値判定** | 30 s 以上接続が続いたかどうかで「成功／失敗」を判別 |
| **詳細ログ** | INFO / WARN / ERROR / DEBUG の 4 レベルでコンソール出力 |
| **Keep‑Alive** | ServerAliveInterval を自動付与しアイドル切断を軽減 |
| **Key／Password 両対応** | 鍵認証・パスワード認証どちらでも利用可能 |
| **Idempotent** | 孤児プロセスを残さず、何度でもリラン可能 |

---

## 前提条件
| 項目 | バージョン・要件 |
|------|----------------|
| **OS** | Windows 10/11, Windows Server 2019+ |
| **PowerShell** | 5.1 以上（PowerShell 7 でも動作確認済み） |
| **OpenSSH クライアント** | `ssh.exe` が PATH 上に存在すること (Windows 機能 or Git for Windows など) |

---

## インストール
```powershell
# 任意のフォルダにコピー
Invoke-WebRequest -Uri https://example.com/AutoSSHWatchdog.ps1 -OutFile AutoSSHWatchdog.ps1
```

---

## クイックスタート
```powershell
# スクリプトを実行
.\AutoSSHWatchdog.ps1
# プロンプトに従ってユーザー名・ホスト名・鍵ファイルなどを入力
```

> **ヒント:** パラメータをハードコードしたラッパースクリプトを別途作ると無人実行しやすくなります。

---

## パラメータ一覧
| 変数 | 既定値 | 意味 |
|------|--------|------|
| `sshUser` | ― | SSH ユーザー名 |
| `sshHost` | ― | SSH ホスト名 / IP |
| `sshPort` | 22 | SSH ポート |
| `sshKeyPath` | 空欄 | 秘密鍵パス（空ならパスワード認証） |
| `successfulConnectionThresholdSeconds` | 30 | 接続を「確立」と判定する秒数 |
| `maxRetries` | 3 | 切断時の再接続最大回数 |
| `retryDelaySeconds` | 5 | 再接続間隔 (秒) |
| `initialConnectWaitSeconds` | 3 | ssh.exe 起動後の成立判定待ち時間 (秒) |
| `sessionMonitoringIntervalSeconds` | 5 | セッション監視間隔 (秒) |
| `serverAliveIntervalSeconds` | 5 | Keep‑Alive 送信間隔 (`-o ServerAliveInterval`) |

---

## 動作フロー
```text
┌─[Start]──────────────────────────────────────────┐
│ Prompt for user/host/key → Build ssh arguments   │
└──────────────────────────────────────────────────┘
        │
        ▼
┌─ Launch ssh.exe (PID n) ─────────────────────────┐
│ Wait initial 3 s                                 │
│ ├─終了していれば → Warn & Retry                  │
│ └─生存ならば → Monitor every 5 s                 │
│       │                                          │
│       │>= 30 s                                   │
│       ▼                                          │
│   Mark as “Established”                          │
│                                                  │
│ (ssh.exe Exit)                                   │
└────────┬─────────────────────────────────────────┘
         │ ExitCode = 0 & Established  → Success ✨
         │ ExitCode ≠ 0                → Retry ≤3
         └─────────────────────────────────────────
```

---

## ログレベル
| レベル | 用途 | 例 |
|--------|------|----|
| `INFO`  | 通常進行 | 接続試行開始、再接続待ち |
| `WARN`  | 予期せぬ事象 | 異常終了した PID, 未確立での切断 |
| `ERROR` | 全試行失敗 | ネットワーク不可、認証失敗など |
| `DEBUG` | 詳細デバッグ | (`Write-Log "... DEBUG"`) を自作で追加可能 |

---

## カスタマイズ例
### ① 再接続回数を 10 回に変更
```powershell
[int]$maxRetries = 10
```

### ② 監視対象コマンドをリモート実行
```powershell
$remoteCommandToRun = "tail -F /var/log/syslog"
$sshArguments += $remoteCommandToRun
```

### ③ ログをファイルにも保存
```powershell
function Write-Log {
    ...
    Add-Content -Path ".\AutoSSHWatchdog.log" -Value $logEntry
}
```

---

## トラブルシューティング
| 症状 | 原因候補 | 対処 |
|------|----------|------|
| すぐに `Exit code 255` | 鍵／パスワード不一致、HostKey 変更 | `ssh` 単独で接続し確認 |
| Established 前に切断が続く | Firewall/Idle timeout | `serverAliveIntervalSeconds` を短く |
| 再接続が止まらない | サーバ側で `MaxSessions` 制限 | SSHD 設定を見直し |
| `ssh.exe` が見つからない | PATH 未設定 | `C:\Windows\System32\OpenSSH\` を PATH へ |

---

## 実務での利用例
1. **メンテナンス検知**  
   Azure Firewall 越しに常時 SSH し、RST パケットで計画外切断がないか確認。
2. **バックアップバッチ**  
   長時間 rsync を走らせる環境で WAN 瞬断があっても自動復旧。
3. **監視サーバのログ tail**  
   `tail -F` をリモートで走らせ、一時的なネットワーク断でもログストリームを維持。

---

## 付録
## パスワードレスSSH
Windows (client) で鍵ペアを作り、公開鍵を Ubuntu (server) の ~/.ssh/authorized_keys に登録すれば、以後はパスワード無しで ssh ubuntu@server が可能になります。
### Windows で鍵ペアを生成
```powershell
# PowerShell で実行
ssh-keygen -t ed25519 -C "windows-to-ubuntu"  # 推奨アルゴリズム
# → 何も変更しなければ
#    公開鍵: C:\Users\<YOU>\.ssh\id_ed25519.pub
#    秘密鍵: C:\Users\<YOU>\.ssh\id_ed25519
```

### 公開鍵を Ubuntu に登録
```shell
# 公開鍵内容を変数へ
$key = Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub

# 1 行でリモートに追記（SSH で echo）
ssh ubuntu@<SERVER_IP> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo $key >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

## ライセンス
MIT License — 詳細は `LICENSE` ファイルを参照してください。
