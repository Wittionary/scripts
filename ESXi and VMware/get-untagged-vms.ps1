Connect-VIServer
$TaggedVMs = Get-TagAssignment | Where-Object {$_.Tag -match "Veeam Backups"}
$AllVMs = Get-VM

Compare-Object -ReferenceObject $AllVMs.Name -DifferenceObject $TaggedVMs.Entity | Where-Object {$_.SideIndicator -eq "<="}