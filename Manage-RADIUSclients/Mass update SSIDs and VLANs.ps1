<# DESCRIPTION:
Rename VLANs 2 and3 to "WIFI-GUEST" and "WIFI-PROD" 
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

$ChangedNetworks = @()
foreach ($Network in $Networks) {
    # https://developer.cisco.com/meraki/api/#!get-network-vlans
    $api.url = "/networks/$($Network.id)/vlans"
    $uri = $api.endpoint + $api.url
    $VLANs = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json

    foreach ($VLAN in $VLANs) {
        $VLANNewConfig = @{}
        if (($VLAN.name -match "guest") -and ($VLAN.name -ne "WIFI-GUEST") -and ($VLAN.id -eq 2)) { #  -or ($VLAN.name -eq "WIFI-GUEST")
            $VLANNewConfig.name = "WIFI-GUEST" # Rename the VLAN
            if (($VLAN.groupPolicyId -ne "") -and ($null -ne $VLAN.groupPolicyId)) {
                $VLANNewConfig.groupPolicyId = "" # Remove group policy
            }
            
        }
        if (($VLAN.name -match "891W") -and ($VLAN.id -eq 3)) { #  -or ($VLAN.name -eq "NSM-WIFI-PROD")
            $VLANNewConfig.name = "WIFI-PROD" # Rename the VLAN
            if (($VLAN.groupPolicyId -ne "") -and ($null -ne $VLAN.groupPolicyId)) {
                $VLANNewConfig.groupPolicyId = "" # Remove group policy
            }
        }

        # Only make requests to VLANs that need changes made
        if ($VLANNewConfig.Count -gt 0) {
            # https://developer.cisco.com/meraki/api/#!update-network-vlan
            $api.url = "/networks/$($Network.id)/vlans/$($VLAN.id)"
            $uri = $api.endpoint + $api.url
            $Body = $VLANNewConfig | ConvertTo-Json
            Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec
            
            try {
                $UpdateVLANResponse = Invoke-WebRequest -Uri $uri -Method PUT -Headers $Header -Body $Body -ea Stop | ConvertFrom-Json
                Write-Host "--------------SUCCESS!`nNetwork name: $($Network.name)
                VLAN name and id: $($VLAN.name) - $($VLAN.id)
                ^^^^^^^^^^^^^^END SUCCESS!"
                $ChangedNetworks += $Network
            }
            catch {
                Write-Error "Network name: $($Network.name)
                VLAN name and id: $($VLAN.name) - $($VLAN.id)
                Submitted body: $Body
                To endpoint: $($api.url)"
            }
        }
        
        
    }

    # https://developer.cisco.com/meraki/api/#/rest/api-endpoints/ssids/get-network-ssids
    $api.url = "/networks/$($Network.id)/ssids"
    $uri = $api.endpoint + $api.url
    $SSIDs = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json

    foreach ($SSID in $SSIDs) {
        $SSIDNewConfig = @{}

        # Guest wifi SSIDs that have not yet been changed
        if ((($SSID.name -match "guest") -and ($SSID.name -ne "WIFI-GUEST") -and ($SSID.authMode -eq "psk"))) { #  -or ($SSID.name -eq "WIFI-GUEST")
            $SSIDNewConfig.name = "WIFI-GUEST" # Rename the SSID
            $SSIDNewConfig.wpaEncryptionMode = "WPA2 only"
            $SSIDNewConfig.encryptionMode = "wpa"
        }
        
        # Prod wifi SSIDs that have not yet been changed
        if ($SSID.authMode -match "radius") { #  -or ($SSID.name -eq "WIFI-PROD")
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

<#
# Reboot only devices/networks that have had changes made to them
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
#>