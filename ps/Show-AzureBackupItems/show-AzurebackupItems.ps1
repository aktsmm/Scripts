Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
$vaults = Get-AzRecoveryServicesVault

        "------"
    foreach ($vault in $vaults)
    {
             "Recovery Services container name :"  + $vault.name
            $backupItem = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -VaultId $vault.ID # | Select-Object FriendlyName

            if($null -ne $backupItem){
                "Backup Item Name :" 
            $backupItem
            }else{
                "Backup Item Name :None" 
            }

        "------"
    }


    Read-Host -Prompt "Script Done! Press Enter to exit"
