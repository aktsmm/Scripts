# Get the current tenant ID
$tenantId = az account show --query tenantId -o tsv
# Get all subscriptions under the same tenant
$subscriptions = az account list --query "[?homeTenantId=='$tenantId'].id" -o tsv

# Array to store all results
$allConfigs = @()

foreach ($sub in $subscriptions) {
    Write-Host "`n==== Subscription: $sub ====" -ForegroundColor Cyan

    # Get maintenance configurations in JSON format
    $json = az maintenance configuration list --subscription $sub --output json | ConvertFrom-Json

    # Skip if no configurations found
    if ($json.Count -eq 0) {
        Write-Host "(No configurations found)" -ForegroundColor DarkGray
        continue
    }

    # Display configurations in table format
    $json | Format-Table Name, Location, MaintenanceScope, ResourceGroup, StartDateTime, RecurEvery, TimeZone, Visibility

    # Add each configuration to the array for CSV output
    foreach ($item in $json) {
        $allConfigs += [PSCustomObject]@{
            SubscriptionId     = $sub
            Name               = $item.name
            Location           = $item.location
            MaintenanceScope   = $item.maintenanceScope
            ResourceGroup      = $item.resourceGroup
            StartDateTime      = $item.startDateTime
            RecurEvery         = $item.recurEvery
            TimeZone           = $item.timeZone
            Visibility         = $item.visibility
        }
    }
}

# Export results to CSV in the current directory
$csvPath = Join-Path -Path (Get-Location) -ChildPath "maintenance-configurations.csv"
$allConfigs | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`n✅ CSV export completed: $csvPath" -ForegroundColor Green
