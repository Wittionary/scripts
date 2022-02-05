Param(
    [Parameter(Mandatory=$true)]
    [String]$SharedSecret
)

Import-Module "E:\scripts\operations\Manage-RADIUSclients\NSM-Meraki-Module.psm1" -Force
Import-Module "E:\scripts\operations\Manage-RADIUSclients\Manage-RADIUSclients.psm1" -Force

$RadiusServers = @("nps01.domain.local","nps02.domain.local","nps03.domain.local")

$TeleworkerGateways = Get-MerakiTeleworkerGateways
Add-RadiusClients -Clients $TeleworkerGateways -Servers $RadiusServers -SharedSecret $SharedSecret