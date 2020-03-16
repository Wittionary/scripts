param($VM)

Connect-VIServer
Get-VM -Name $VM | Restart-VM -Confirm:$false