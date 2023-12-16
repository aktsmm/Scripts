Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
$vaults = Get-AzRecoveryServicesVault
    foreach ($vault in $vaults)
    {
             "Recovery Services container name :"  + $vault.name
    }


    Read-Host -Prompt "Script Done! Press Enter to exit"

