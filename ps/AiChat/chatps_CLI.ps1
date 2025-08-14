# 履歴なし版 AI チャット（毎回独立）

$url = '<YOUR_AZURE_FUNCTION_URL>?code=<YOUR_FUNCTION_CODE>'

function ai {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Text)
    $body = @{messages=@(@{role='user'; content=($Text -join ' ')})} | ConvertTo-Json -Depth 3
    try {
        $r = Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 30
        $r.reply ?? ($r | ConvertTo-Json -Depth 2)
    } catch {
        "エラー: $($_.Exception.Message)"
    }
}
