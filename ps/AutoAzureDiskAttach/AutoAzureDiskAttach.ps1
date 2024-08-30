# Set necessary variables
$tenantId = 'yourEntraIDTenantID'
$subscriptionId = 'yourSubscriptionID'
$resourceGroupName = "yourResourceGRName"
$vmName = "yourVM"
$diskName = "yourDisk"
$location = "JapanEast"
$lun = "0"
$dletter = "E"


# Define log file path with current timestamp
$timestamp = Get-Date -Format "yyMMddHHmm"
$logFilePath = ".\$timestamp`_diskattach.log"

# Function to write logs
function Write-Log {
    param (
        [string]$message
    )
    $message | Out-File -Append -FilePath $logFilePath
}

# Connect to Azure
Write-Log "Connecting to Azure..."
Connect-AzAccount -Identity | Out-Null
Write-Log "Connected to Azure."

# Specify Azure subscription
Write-Log "Setting Azure subscription context..."
Set-AzContext -SubscriptionId $subscriptionId -TenantId $tenantId | Out-Null
Write-Log "Azure subscription context set."

# Attach managed disk to VM
Write-Log "Retrieving VM and disk information..."
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -VMName $vmName
$disk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName

# Check if LUN is already in use
$existingDataDisk = $vm.StorageProfile.DataDisks | Where-Object { $_.Lun -eq $lun }
if ($existingDataDisk) {
    Write-Log "Completed: A disk is already attached at LUN $lun."
    return
}

# Add data disk if LUN is available
Write-Log "Adding disk to VM..."
$vm = Add-AzVMDataDisk -VM $vm -Name $diskName -CreateOption Attach -ManagedDiskId $disk.Id -Lun $lun
Write-Log "Disk added to VM."

# Update the VM configuration
Write-Log "Updating VM configuration..."
Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm
Write-Log "VM configuration updated."

# Connect to VM and assign a drive letter
Write-Log "Retrieving offline disks..."
$ldisk = Get-Disk | Where-Object PartitionStyle -ne 'RAW' | Where-Object OperationalStatus -eq 'Offline'

# Check disk is offline
if ($ldisk -eq $null) {
    Write-Log " Completed:No valid offline disk found with the specified conditions."
    Write-Host " Completed:No valid offline disk found with the specified conditions."
    exit
}

Set-Disk -Number $ldisk.Number -IsOffline $false
Set-Disk -Number $ldisk.Number -IsReadOnly $false

$partition = Get-Partition -DiskNumber $ldisk.Number | Where-Object DriveLetter -eq $null
if ($partition) {
    $partition | Set-Partition -NewDriveLetter $dletter
}

Write-Log "Script completed."
