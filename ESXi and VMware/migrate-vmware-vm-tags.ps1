Connect-VIServer
$ToBeRetagged = Get-TagAssignment | Where-Object {$_.Tag -match "Veeam Backups/LEGACY-veeam-creds:veeam_svc\+app-aware"}

# Remove old tag first
Remove-TagAssignment -TagAssignment $ToBeRetagged

foreach ($Retag in $ToBeRetagged) {
    # Formerly did $(Get-VM ...) for Entity param
    New-TagAssignment -Tag "veeam-creds:veeam_svc+app-aware" -Entity $Retag.Entity.Name
}