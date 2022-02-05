Param(
    [Parameter(Mandatory=$true)]
    [String]$SharedSecret
)

Import-Module "E:\scripts\operations\Manage-RADIUSclients\NSM-Meraki-Module.psm1" -Force
Import-Module "E:\scripts\operations\Manage-RADIUSclients\Manage-RADIUSclients.psm1" -Force

$RadiusServers = @("nps01.domain.local","nps02.domain.local","nps03.domain.local")

$APs = Get-MerakiAPs
Add-RadiusClients -Clients $APs -Servers $RadiusServers -SharedSecret $SharedSecret