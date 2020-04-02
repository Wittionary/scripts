# PowerCLI
param(
    $vSphereServer = "",
    $DestinationPath = "C:\Users\$env:UserName\Downloads\"
)

Connect-VIServer $vSphereServer
$AllESXiHosts = Get-VMHost
$ConnectedESXiHosts = Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}
Write-Host "$($ConnectedESXiHosts.Count) out of $($AllESXiHosts.Count) are connected and will be backed up."

foreach ($ConnectedESXiHost in $ConnectedESXiHosts) {
    $ConnectedESXiHost | Get-VMHostFirmware -BackupConfiguration -DestinationPath $DestinationPath
}
