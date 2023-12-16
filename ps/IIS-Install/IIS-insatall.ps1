Install-WindowsFeature -name Web-Server -IncludeManagementTools

$iisstart_path = Join-Path $Env:SystemDrive "inetpub\wwwroot\iisstart.htm"
Remove-Item $iisstart_path
Add-Content -Path $iisstart_path -Value $("Hi, this is " + $Env:ComputerName)