param($vSphereServer,$VM)

$Creds = Get-Credential
Connect-VIServer -Server $vSphereServer -Credential $Creds
Get-VM -Name $VM | Restart-VM -Confirm:$false