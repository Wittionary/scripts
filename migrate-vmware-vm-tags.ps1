$ToBeRetagged = Get-TagAssignment | ? {$_.Tag -match "Veeam Backups/veeam-creds:veeam_svc\+app-aware"}

# Veeam Backups/LEGACY-veeam-creds:veeam_svc+app-aware
# Remove old tag first
Remove-TagAssignment -TagAssignment $ToBeRetagged

foreach ($Retag in $ToBeRetagged) {
    New-TagAssignment -Tag "LEGACY-veeam-creds:veeam_svc+app-aware" -Entity $(Get-vm $Retag.Entity)
}
