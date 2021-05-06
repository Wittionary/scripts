Connect-VIServer
$ToBeRetagged = Get-TagAssignment | Where-Object {$_.Tag -match "Veeam Backups/veeam-creds:veeam_svc\+not-app-aware"}

# Remove old tag first
Remove-TagAssignment -TagAssignment $ToBeRetagged

foreach ($Retag in $ToBeRetagged) {
    # Formerly did $(Get-VM ...) for Entity param
    New-TagAssignment -Tag "LEGACY-veeam-creds:veeam_svc+not-app-aware" -Entity $Retag.Entity.Name
}
