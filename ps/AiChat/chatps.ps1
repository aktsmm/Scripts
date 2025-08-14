# AI チャット GUI アプリ
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$url = '<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>'

# URLがプレースホルダーの場合、直接入力フォームを表示
if ($url -eq '<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>') {
    $inputForm = New-Object System.Windows.Forms.Form
    $inputForm.Text = "URL入力"
    $inputForm.Size = New-Object System.Drawing.Size(400, 150)
    $inputForm.StartPosition = "CenterScreen"

    $inputBox = New-Object System.Windows.Forms.TextBox
    $inputBox.Location = New-Object System.Drawing.Point(10, 30)
    $inputBox.Size = New-Object System.Drawing.Size(360, 23)
    $inputForm.Controls.Add($inputBox)

    # プレースホルダーを示すラベルを追加
    $placeholderLabel = New-Object System.Windows.Forms.Label
    $placeholderLabel.Text = "例: <YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>"
    $placeholderLabel.Location = New-Object System.Drawing.Point(10, 5)
    $placeholderLabel.Size = New-Object System.Drawing.Size(360, 20)
    $placeholderLabel.ForeColor = [System.Drawing.Color]::Gray
    $placeholderLabel.Font = New-Object System.Drawing.Font("BIZ UDPゴシック", 8)
    $inputForm.Controls.Add($placeholderLabel)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(150, 70)
    $okButton.Add_Click({ $inputForm.DialogResult = [System.Windows.Forms.DialogResult]::OK })
    $inputForm.Controls.Add($okButton)

    $inputBox.Focus()  # フォーム表示時に入力ボックスをアクティブにする

    # プレースホルダーを設定
    $inputBox.Text = "<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>"
    $inputBox.ForeColor = [System.Drawing.Color]::Gray

    # フォーカス時にプレースホルダーをクリア
    $inputBox.Add_GotFocus({
        if ($inputBox.Text -eq "<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>") {
            $inputBox.Text = ""
            $inputBox.ForeColor = [System.Drawing.Color]::Black
        }
    })

    # フォーカスが外れたときにプレースホルダーを再表示
    $inputBox.Add_LostFocus({
        if ([string]::IsNullOrWhiteSpace($inputBox.Text)) {
            $inputBox.Text = "<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>"
            $inputBox.ForeColor = [System.Drawing.Color]::Gray
        }
    })

    if ($inputForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $url = $inputBox.Text.Trim()
        if (-not $url) {
            Write-Host "URLが設定されていないため、スクリプトを終了します。"
            exit
        }
    } else {
        Write-Host "URL入力がキャンセルされました。スクリプトを終了します。"
        exit
    }
}

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

# フォームの背景色をグラデーション風に変更
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f0f4f8")

# チャット履歴表示エリア
$chatBox = New-Object System.Windows.Forms.RichTextBox
$chatBox.Location = New-Object System.Drawing.Point(10, 10)
$chatBox.Size = New-Object System.Drawing.Size(460, 280)
$chatBox.ReadOnly = $true
$chatBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
$chatBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$chatBox.Font = New-Object System.Drawing.Font("BIZ UDPゴシック", 10)

# 入力エリア
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(10, 300)
$inputBox.Size = New-Object System.Drawing.Size(360, 23)
$inputBox.Font = New-Object System.Drawing.Font("BIZ UDPゴシック", 10)
$inputBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e8f0fe")
$inputBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D

# 送信ボタン
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Location = New-Object System.Drawing.Point(380, 300)
$sendButton.Size = New-Object System.Drawing.Size(90, 23)
$sendButton.Text = "送信"
$sendButton.Font = New-Object System.Drawing.Font("BIZ UDPゴシック", 10, [System.Drawing.FontStyle]::Bold)
$sendButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4caf50")
$sendButton.ForeColor = [System.Drawing.Color]::White
$sendButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# クリアボタン
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Location = New-Object System.Drawing.Point(380, 330)
$clearButton.Size = New-Object System.Drawing.Size(90, 23)
$clearButton.Text = "クリア"
$clearButton.Font = New-Object System.Drawing.Font("BIZ UDPゴシック", 10, [System.Drawing.FontStyle]::Bold)
$clearButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f44336")
$clearButton.ForeColor = [System.Drawing.Color]::White
$clearButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# ボタンのホバー効果を追加
$sendButton.Add_MouseEnter({ $sendButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#45a049") })
$sendButton.Add_MouseLeave({ $sendButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4caf50") })

$clearButton.Add_MouseEnter({ $clearButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e53935") })
$clearButton.Add_MouseLeave({ $clearButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f44336") })

# 送信処理
function Send-Message {
    $message = $inputBox.Text.Trim()
    if (-not $message) { return }
    
    # ユーザーメッセージを表示
    $chatBox.SelectionColor = [System.Drawing.Color]::Blue
    $chatBox.AppendText("あなた: $message`n")
    
    # AI応答中表示
    $chatBox.SelectionColor = [System.Drawing.Color]::Gray
    $chatBox.AppendText("AIおじ: 考え中...`n")
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

# フォームロード時に入力フィールドをアクティブにする
$form.Add_Shown({ $inputBox.Focus() })

# 初期フォーカス
$inputBox.Focus()

# フォーム表示
$form.ShowDialog()