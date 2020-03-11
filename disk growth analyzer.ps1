$server = "server01.fqdn.local"
$IntervalInMinutes = 5
<#
C drive is 23.0 GB free
D drive 51.0 GB free
E drive 284 GB free
#>
for ($i=0; $i -lt 16; $i++) {
    Invoke-Command -ComputerName $server {Get-PSDrive C} | Select-Object PSComputerName,Used,Free
    Start-Sleep -s ($IntervalInMinutes*60) # Every x minutes
}
