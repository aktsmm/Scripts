# AzWinAgentSwitch.ps1

## 概要

このスクリプトは、Azure 仮想マシン上の「WindowsAzureGuestAgent」サービス（Azure VM ゲストエージェント）の状態を自動で切り替える PowerShell スクリプトです。管理者権限で実行し、サービスが起動中なら停止、停止中なら起動します。日本語・英語の自動表示切替に対応しています。

## 使いどころ・実用例

- **障害テスト**：ゲストエージェントを意図的に停止し、Azure 監視やアラートが正しく発報されるかを検証したいときに便利です。
- **運用検証**：サービスの自動復旧や監視設定のテスト時に、手軽に状態を切り替えられます。
- **トラブルシュート**：ゲストエージェントの動作確認や再起動が必要な場合にも活用できます。

> 実際に私は、Guest Agent を止めて障害テストを行い、アラートが発報されるかを検証する目的で本スクリプトを作成しました。

## 使い方

1. **管理者権限**で PowerShell を起動します。
2. スクリプトを実行します（例: `./AzWinAgentSwitch.ps1`）。
3. サービスの状態に応じて自動で開始または停止し、結果が表示されます。
4. 何かキーを押すとウィンドウが閉じます。

## 注意事項

- サービス名は「WindowsAzureGuestAgent」に固定されています。
- 管理者権限が必要です。権限がない場合、サービスの状態取得や操作に失敗します。
- スクリプトは OS の UI 言語を自動判定し、日本語または英語でメッセージを表示します。

## コード例（抜粋・コメント付き）

```powershell
# サービスの状態を取得し、Runningなら停止、Stoppedなら起動
$service = Get-Service -Name $serviceName -ErrorAction Stop
if ($service.Status -eq "Running") {
    Write-Host $messages[$lang].running -ForegroundColor Yellow
    Stop-Service -Name $serviceName -Force
    Write-Host $messages[$lang].stoppedDone -ForegroundColor Green
} elseif ($service.Status -eq "Stopped") {
    Write-Host $messages[$lang].stopped -ForegroundColor Yellow
    Start-Service -Name $serviceName
    Write-Host $messages[$lang].startedDone -ForegroundColor Green
}
```

> 各部分にコメントを付与し、何をしているか明確にしています。

## より実践的な疑似障害シナリオ例

### 1. ゲストエージェント停止＋拡張機能デプロイ失敗

- **手順**
  1. スクリプトでゲストエージェントを停止。
  2. 停止中に Azure ポータルから「拡張機能の追加・更新」を実施。
  3. 拡張機能のデプロイ失敗アラートが発報されるか確認。
- **ポイント**
  - 拡張機能の自動デプロイ失敗が重大インシデントにつながるため、検証価値が高い。

### 2. ゲストエージェント停止＋ Azure Backup/自動パッチ適用の失敗

- **手順**
  1. ゲストエージェント停止中に Azure Backup や自動パッチ適用のスケジュールを実行。
  2. バックアップやパッチ適用が失敗し、アラートが発報されるか確認。
- **ポイント**
  - 重要な運用自動化が失敗した場合の検知・通知フローを検証できる。

### 3. ゲストエージェント停止＋ VM 操作不可シナリオ

- **手順**
  1. ゲストエージェント停止中に「シャットダウン」「再起動」「パスワードリセット」などの VM 操作を Azure ポータルから実行。
  2. 操作が失敗し、アラートや運用通知が発報されるか確認。
- **ポイント**
  - ゲストエージェント依存の運用操作が失敗した際の影響範囲や通知経路を把握できる。

### 4. ゲストエージェント停止＋ Log Analytics/監査ログ連携の確認

- **手順**
  1. ゲストエージェント停止中に Log Analytics や監査ログ連携の動作を確認。
  2. ログ収集や監査イベントが欠落し、アラートや検知ができるかを確認。
- **ポイント**
  - セキュリティ監査や運用監視の堅牢性を検証できる。

---

### 現場 Tips

- これらのシナリオは、Azure Monitor の「アクティビティログ」「メトリック」「ログアラート」などを活用して検証できます。
- テスト後は必ずゲストエージェントを再起動し、正常状態に戻してください。

#### 参考

- [Azure VM ゲストエージェントの監視とトラブルシューティング](https://learn.microsoft.com/ja-jp/azure/virtual-machines/extensions/agent-windows#monitor-and-troubleshoot-the-azure-vm-agent) #microsoft.docs.mcp
- [Azure Monitor でのアラート ルールの作成](https://learn.microsoft.com/ja-jp/azure/azure-monitor/alerts/alerts-unified-portal) #microsoft.docs.mcp
- [Azure Backup の障害とアラート](https://learn.microsoft.com/ja-jp/azure/backup/backup-azure-monitoring-integrate) #microsoft.docs.mcp
- [Azure Policy の概要](https://learn.microsoft.com/ja-jp/azure/governance/policy/overview) #microsoft.docs.mcp
