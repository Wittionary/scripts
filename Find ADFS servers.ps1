# https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-addomaincontroller?view=winserver2012-ps
# Currently only checks DCs for the ADFS role
# TODO: search all servers in AD for ADFS role
$allDCs = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ }

foreach ($DC in $allDCs) {
    Get-WindowsFeature adfs-federation -ComputerName $DC.HostName
}