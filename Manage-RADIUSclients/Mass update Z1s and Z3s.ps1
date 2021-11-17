<# DESCRIPTION:
Rename VLANs 2 and3 to "NSM-WIFI-GUEST" and "NSM-WIFI-PROD" 
Remove group policies from VLANs 2 and 3 (WiFi Guest and Prod respectively)
Rename SSIDs

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
#$Networks = $Networks | Select-Object -First 3

# Limit to networks that have teleworker gateways
$TeleworkerGateways = @()
foreach ($Network in $Networks) {
    # https://developer.cisco.com/meraki/api/#!get-network-devices
    $api.url = "/networks/$($Network.id)/devices"
    $uri = $api.endpoint + $api.url
    $Devices = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json
    Start-Sleep -Milliseconds 201
    
    $HasTeleworkerGateway = $false
    foreach ($Device in $Devices) {
        if (($Device.Model -eq "Z1") -or ($Device.Model -eq "Z3")) {
            $HasTeleworkerGateway = $true
        }
    }

    if ($HasTeleworkerGateway -eq $true) {
        $TeleworkerGateways += $Network
    }
}
$Networks = $TeleworkerGateways

$ChangedNetworks = @()
foreach ($Network in $Networks) {
    # https://developer.cisco.com/meraki/api/#/rest/api-endpoints/ssids/get-network-ssids
    $api.url = "/networks/$($Network.id)/ssids"
    $uri = $api.endpoint + $api.url
    $SSIDs = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    Start-Sleep -Milliseconds 201
    
    foreach ($SSID in $SSIDs) {
        $SSIDNewConfig = @{}
        if ((($SSID.authMode -match "radius") -and ($SSID.enabled -eq $true)) -or ($SSID.name -eq "WIFI-PROD")) {
            $SSIDNewConfig.name = "WIFI-PROD" # Rename the SSID
            $SSIDNewConfig.wpaEncryptionMode = "WPA2 only"
            $SSIDNewConfig.radiusFailoverPolicy = "Deny access"
            $SSIDNewConfig.radiusLoadBalancingPolicy = "Round robin"
            $SSIDNewConfig.radiusServers = @(
                @{
                host = "10.0.0.1";
                secret = "the actual PSK";
                port = 1812;
                }
                @{
                host= "10.2.0.1";
                secret= "the actual PSK";
                port= 1812;
                };
            )
        }

        # Only make requests to SSIDs that need changes made
        if ($SSIDNewConfig.Count -gt 0) {
            $api.url = "/networks/$($Network.id)/ssids/$($SSID.number)"
            $uri = $api.endpoint + $api.url
            $Body = $SSIDNewConfig | ConvertTo-Json
            Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec

            try {
                $UpdateSSIDResponse = Invoke-WebRequest -Uri $uri -Method PUT -Headers $header -Body $Body -ea Stop | ConvertFrom-Json
                Write-Host "--------------SUCCESS!`nNetwork name: $($Network.name)
                SSID name: $($SSID.name) -> $($SSIDNewConfig.name)
                Submitted body: $Body
                To endpoint: $($api.url)
                ^^^^^^^^^^^^^^END SUCCESS!"
                $ChangedNetworks += $Network
            }
            catch {
                Write-Error "Network name: $($Network.name)
                SSID name: $($SSID.name) -> $($SSIDNewConfig.name)
                Submitted body: $Body
                To endpoint: $($api.url)"
            }
        }
    }

}

Write-Host "Preparing to reboot devices..."
Start-Sleep -s 60
Write-Error "WARNING!`nYou're about to reboot a bunch of devices. Are you sure you want to do that?" -ErrorAction Inquire
foreach ($ChangedNetwork in $ChangedNetworks) {
    $api.url = "/networks/$($Network.id)/devices" 
    $uri = $api.endpoint + $api.url
    $Devices = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json
    $Devices = $Devices | Where-Object {($_.Model -eq "Z1") -or ($_.Model -eq "Z3")}

    foreach ($Device in $Devices) {
        # https://developer.cisco.com/meraki/api/#!reboot-network-device
        $api.url = "/networks/$($ChangedNetwork.id)/devices/$($Device.serial)/reboot"
        $uri = $api.endpoint + $api.url
        Invoke-WebRequest -Uri $uri -Method POST -Headers $Header | ConvertFrom-Json
        Start-Sleep -Milliseconds 201
    }
}