<# DESCRIPTION:

#>
# Ensures that Invoke-WebRequest uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Declare variables
$api = @{
    "endpoint" = 'https://api.meraki.com/api/v0'
    "key" = 'actual API key here'
    }
$Header = @{
        "X-Cisco-Meraki-API-Key" = $api.key
        "Content-Type" = 'application/json'
    }
$orgID = 123456 # Actual org ID can be found in Meraki UI

# Get all networks
$api.url = "/organizations/$orgID/networks"
$uri = $api.endpoint + $api.url
$Networks = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json
$Networks = $Networks | Sort-Object -Property Name # Alphabetize the network list

$ChangedNetworks = @()
foreach ($Network in $Networks) {
    # https://developer.cisco.com/meraki/api/#!get-network-vlans
    $api.url = "/networks/$($Network.id)/vlans"
    $uri = $api.endpoint + $api.url
    $VLANs = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json
    $VLANs = $VLANs | where-object {$_.id -eq 1} # VLAN 1
    Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec

    foreach ($VLAN in $VLANs) {
        Write-Host "$($VLAN.applianceIp)"
    }
}