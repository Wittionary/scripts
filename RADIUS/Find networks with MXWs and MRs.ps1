<# DESCRIPTION:
Return networks that have both MXs with integrated wireless and MRs
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

$NetworksWithBoth = @() # Both MXWs and MRs
foreach ($Network in $Networks) {
    # https://developer.cisco.com/meraki/api/#!get-network-devices
    $api.url = "/networks/$($Network.id)/devices"
    $uri = $api.endpoint + $api.url
    $Devices = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    Start-Sleep -Milliseconds 201

    $HasMR = $false
    $HasMXW = $false
    foreach ($Device in $Devices) {
        if ($Device.Model -match "MR") {
            $HasMR = $true
        } elseif ($Device.Model.startswith("MX") -and $Device.Model.endswith("W")) {
            $HasMXW = $true
        }
    }

    if ($HasMXW -and $HasMR) {
        $NetworksWithBoth += $Network.name
    }
}

Write-Host $NetworksWithBoth