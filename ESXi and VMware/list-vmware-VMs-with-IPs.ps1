Connect-VIServer

$VMs = Get-VM
foreach ($VM in $VMs) {
    $IPaddress = get-vmguest -VM $VM.Name | Select-Object IPaddress
    $IPaddress = $IPaddress.IPAddress
    Write-host "$($VM.Name) - $($IPaddress)"
}