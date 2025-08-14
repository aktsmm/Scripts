# 履歴なし版 AI チャット（毎回独立）
$url = 'https://functions10460-e4a3bxfcajggdggr.japaneast-01.azurewebsites.net/api/SendToAzureAI?code=OZlpldbGE0MK4C33LXf9qK24Mgn1ughCyxIZFAIl4RVnAzFuNr5aPg=='

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