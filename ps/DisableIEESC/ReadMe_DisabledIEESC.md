
# Disable-IEESC.ps1 – ReadMe  

> **結論 (TL;DR)** – `Disable-IEESC.ps1` を実行すれば **Administrators / Users** 両方の **IE Enhanced Security Configuration (ESC)** が自動で **Off** になります。  
> Bicep から呼び出す場合は **Custom Script Extension** か **Run Command** を選択してください。  

---  

## 1. スクリプト概要  

| 項目 | 内容 |
|------|------|
| ファイル名 | `Disable-IEESC.ps1` |
| 対象 OS | Windows Server 2012 以降 (2016/2019/2022, Azure VM 含む) |
| 権限 | ローカル管理者 (SYSTEM でも可) |
| 動作 | Active Setup レジストリ 2 キーの `IsInstalled` を **0**、`StubPath` を **空文字** に変更 |
| 冪等性 | **Idempotent**（何度実行しても状態変わらず） |

---  

## 2. 手動実行手順  

```powershell
# リモートセッション or ローカル管理者 PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Disable-IEESC.ps1
```  

完了後に **Server Manager** を再読み込み、または再ログオンすると GUI 表示が **Off** に変わります。  

---  

## 3. Bicep からの自動実行  

### 3.1 方法① – Custom Script Extension  
* 例
```bicep
param vmName string
param location string = resourceGroup().location

var scriptUri = 'https://raw.githubusercontent.com/<org>/<repo>/main/Disable-IEESC.ps1'

resource disableIEEsc 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: '${vmName}/DisableIEEsc'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      fileUris: [ scriptUri ]
      commandToExecute: 'powershell -ExecutionPolicy Bypass -File Disable-IEESC.ps1'
    }
  }
}
```  
### 3.2 方法② – Run Command
* 例
```bicep
var disableScript = loadTextContent('./scripts/Disable-IEESC.ps1')

resource runOnce 'Microsoft.Compute/virtualMachines/runCommands@2024-03-01' = {
  name: '${vmName}/DisableIEEsc'
  location: location
  properties: {
    source: {
      script: disableScript
    }
    asyncExecution: false
    timeoutInSeconds: 300
  }
}
```  

#### 特徴  
* **一度だけ実行して終了**。VM イメージをクリーンに保ちたい場合向け。  
* テンプレート変更時には差分が反映され再実行。  

---  

## 4. テスト方法  

```powershell
# 管理者 / ユーザー両方とも 0 であれば成功
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4B3F-8CFC-4F3A74704073}','IsInstalled','StubPath'
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4B3F-8CFC-4F3A74704073}','IsInstalled','StubPath'
```  

---  

## 5. トラブルシューティング  

| 事象 | 対処 |
|------|------|
| GUI が **On** のまま | 再ログオン or `ServerManager` 再読み込み |
| レジストリ変更が戻る | GPO/DSC で再有効化されていないか確認 |
| スクリプトが失敗 | 実行ポリシー / 管理者権限を確認 |

---  


## 6. 参考

* Microsoft Docs – [Enable or disable Internet Explorer Enhanced Security Configuration](https://learn.microsoft.com/previous-versions/troubleshoot/browsers/security-privacy/enhanced-security-configuration-faq)  
* Azure Docs – [Custom Script Extension for Windows](https://learn.microsoft.com/azure/virtual-machines/extensions/custom-script-windows)  
* Azure Docs – [Run Command for Windows VMs](https://learn.microsoft.com/azure/virtual-machines/windows/run-command)  

---  

© 2025 Yamapan
