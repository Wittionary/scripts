# Compare configuration XML size and err towards syncing that one over the other

# Sync needs to get all clients on one server
# Compare to other server
# Whichever server only has the client once, remove that client


param($test)
$UncPath = '\\server.domain.local\share$\scripts\'
Import-Module -Name $UncPath\Manage-RADIUSclients\NSM-Meraki-Module.psm1
Import-Module -Name $UncPath\Manage-RADIUSclients\SafeAdd-RADIUSclient.ps1
$s = Get-MerakiAPs

$s[0] > C:\users\pvl_wallen\desktop\${test}.txt
$SharedSecret >> C:\users\pvl_wallen\desktop\${test}.txt
$RadiusServers >> C:\users\pvl_wallen\desktop\${test}.txt
# editing the script test; does it re-block it?