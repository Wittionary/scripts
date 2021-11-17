<# DESCRIPTION:
Return the public IPs for all Meraki networks with MXs
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

$CsvData = @()
foreach ($Network in $Networks) {
    # https://developer.cisco.com/meraki/api/#!get-network-devices
    $api.url = "/networks/$($Network.id)/devices"
    $uri = $api.endpoint + $api.url
    $Devices = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    Start-Sleep -Milliseconds 201

    foreach ($Device in $Devices) {
        $CsvData += $Device | Where-Object {$_.model -match "MX"} | Select-Object -Property name,lanIp
    }
}

$CsvData | Export-Csv -path 'All branch MX public IPs.csv' -notypeinformation -force

