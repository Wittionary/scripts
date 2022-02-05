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


$NetworkSSIDStatuses = @()
foreach ($Network in $Networks) {
    $api.url = "/networks/$($Network.id)/ssids"
    $uri = $api.endpoint + $api.url
    $SSIDs = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    Start-Sleep -Milliseconds 201

    $HasGuest = $false
    $HasProd = $false
    foreach ($SSID in $SSIDs) {
        if ($SSID.name -match "WIFI-GUEST") {
            $HasGuest = $true
        } elseif ($SSID.name -match "WIFI-PROD") {
            $HasProd = $true
        }
    }

    $NetworkSSIDStatuses += @{
        "Name" = $Network.name;
        "HasGuest" = $HasGuest;
        "HasProd" = $HasProd;
    }
}

# Networks that aren't Teleworker gateways and don't have at least one of the SSIDs
$NetworkSSIDStatuses | ? {(($_.hasprod -eq $false) -or ($_.hasguest -eq $false)) -and ($_.name -notmatch "\.")} | select Name