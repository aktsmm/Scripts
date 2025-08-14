# AI チャット GUI アプリ
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$url = '<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>'

# AI 呼び出し関数
function Get-AIResponse {
    param([string]$message)
    $body = @{messages=@(@{role='user'; content=$message})} | ConvertTo-Json -Depth 3
    try {
        $r = Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 30
        return $r.reply ?? ($r | ConvertTo-Json -Depth 2)
    } catch {
        return "エラー: $($_.Exception.Message)"
    }
}

# フォーム作成
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI チャット"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

# チャット履歴表示エリア
$chatBox = New-Object System.Windows.Forms.RichTextBox
$chatBox.Location = New-Object System.Drawing.Point(10, 10)
$chatBox.Size = New-Object System.Drawing.Size(460, 280)
$chatBox.ReadOnly = $true
$chatBox.BackColor = [System.Drawing.Color]::White
$chatBox.Font = New-Object System.Drawing.Font("メイリオ", 9)

# 入力エリア
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(10, 300)
$inputBox.Size = New-Object System.Drawing.Size(360, 23)
$inputBox.Font = New-Object System.Drawing.Font("メイリオ", 9)

# 送信ボタン
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Location = New-Object System.Drawing.Point(380, 300)
$sendButton.Size = New-Object System.Drawing.Size(90, 23)
$sendButton.Text = "送信"
$sendButton.Font = New-Object System.Drawing.Font("メイリオ", 9)

# クリアボタン
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(380, 330)
$clearButton.Size = New-Object System.Drawing.Size(90, 23)
$clearButton.Text = "クリア"
$clearButton.Font = New-Object System.Drawing.Font("メイリオ", 9)

# 送信処理
function Send-Message {
    $message = $inputBox.Text.Trim()
    if (-not $message) { return }
    
    # ユーザーメッセージを表示
    $chatBox.SelectionColor = [System.Drawing.Color]::Blue
    $chatBox.AppendText("あなた: $message`n")
    
    # AI応答中表示
    $chatBox.SelectionColor = [System.Drawing.Color]::Gray
    $chatBox.AppendText("AI: 考え中...`n")
    $chatBox.ScrollToCaret()
    
    $inputBox.Clear()
    $sendButton.Enabled = $false
    
    # 即座にAI呼び出し（シンプル版）
    try {
        # "考え中..."を削除
        $lines = $chatBox.Lines
        if ($lines.Length -gt 0) {
            $chatBox.Lines = $lines[0..($lines.Length-2)]
        }
        
        # AI呼び出し
        $aiResponse = Get-AIResponse $message
        
        # AI応答を表示
        $chatBox.SelectionColor = [System.Drawing.Color]::DarkGreen
        $chatBox.AppendText("AI: $aiResponse`n`n")
        $chatBox.ScrollToCaret()
    }
    catch {
        $chatBox.SelectionColor = [System.Drawing.Color]::Red
        $chatBox.AppendText("エラーが発生しました`n`n")
    }
    finally {
        $sendButton.Enabled = $true
        $inputBox.Focus()
    }
}

# イベント設定
$sendButton.Add_Click({ Send-Message })
$clearButton.Add_Click({ $chatBox.Clear() })
$inputBox.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") { Send-Message }
})

# コントロールをフォームに追加
$form.Controls.AddRange(@($chatBox, $inputBox, $sendButton, $clearButton))

# 初期フォーカス
$inputBox.Focus()

# フォーム表示
$form.ShowDialog()