function Get-MerakiAPs(){
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
    $networks = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json

    # Enumerate through each network
    foreach ($network in $networks) {
        Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec
        $networkID = $network.id
        $networkName = $network.name

        # Get all the devices at this network
        $api.url = "/networks/$networkID/devices"
        $uri = $api.endpoint + $api.url
        $networkDevices = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
        #returns keys: lanIp, model (needs to start with "MR"), name

        # Enumerate through each device in the network
        foreach ($networkDevice in $networkDevices) {
            # We only care about Meraki Radios (i.e. access points)
            if ($networkDevice.model.StartsWith("MR")) {
                $APname = $networkDevice.name
                $APlanIP = $networkDevice.lanIp

                $clientName = "Meraki_${networkName}_$APname"
                $clientIP = $APlanIP

                $AccessPoint = @{
                    "name" = $clientName
                    "ip" = $clientIP
                }                    
                
                $AccessPoints += $AccessPoint
            
            }
        }

    }

    return $AccessPoints
}

function Get-MerakiMXs(){
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
    $networks = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    # Limit scope for testing
    #$networks = $networks | Where-Object {$_.name -eq "network-name"}

    # Enumerate through each network
    foreach ($network in $networks) {
        Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec
        $networkID = $network.id
        $networkName = $network.name

        # Get all the devices at this network
        $api.url = "/networks/$networkID/devices"
        $uri = $api.endpoint + $api.url
        $networkDevices = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
        #returns keys: lanIp, model (needs to start with "MX"), name
  
        # Enumerate through each device in the network
        foreach ($networkDevice in $networkDevices) {
            # We only care about Meraki Security Appliances
            if ($networkDevice.model.StartsWith("MX")) {
                Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec
                # Get IP to add to MX from the VLAN
                # https://developer.cisco.com/meraki/api/#!get-network-vlans
                $api.url = "/networks/$($Network.id)/vlans"
                $uri = $api.endpoint + $api.url
                $VLANs = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json

                $MXlanIP = ''
                foreach ($VLAN in $VLANs) {
                    if ((($VLAN.name -match "891W") -and ($VLAN.id -eq 3)) -or ($VLAN.name -eq "WIFI-PROD")) {
                        $MXlanIP = $VLAN.applianceIp
                    }
                }
                $MXname = $networkDevice.name

                $clientName = "Meraki_${networkName}_$MXname"
                $clientIP = $MXlanIP

                $SecurityAppliance = @{
                    "name" = $clientName
                    "ip" = $clientIP
                }                    
                
                $SecurityAppliances += $SecurityAppliance
            
            }
        }

    }

    return $SecurityAppliances
}

function Get-MerakiTeleworkerGateways(){
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
    $TeleworkerGateways = @()
    
    # Get all networks
    $api.url = "/organizations/$orgID/networks"
    $uri = $api.endpoint + $api.url
    $networks = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    # Limit scope for testing
    #$networks = $networks | Where-Object {$_.name -eq "network-name"}

    # Enumerate through each network
    foreach ($network in $networks) {
        Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec
        $networkID = $network.id
        $networkName = $network.name

        # Get all the devices at this network
        $api.url = "/networks/$networkID/devices"
        $uri = $api.endpoint + $api.url
        $networkDevices = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
        Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec

        # Enumerate through each device in the network
        foreach ($networkDevice in $networkDevices) {
            # Get IP from VLAN IP
            # https://developer.cisco.com/meraki/api/#!get-network-vlans
            $api.url = "/networks/$($Network.id)/vlans"
            $uri = $api.endpoint + $api.url
            $VLANs = Invoke-WebRequest -Uri $uri -Method GET -Headers $Header | ConvertFrom-Json
            Start-Sleep -Milliseconds 201 # Prevents hitting the rate-limit of 5 reqs/sec
            
            foreach ($VLAN in $VLANs) {
                if ($VLAN.applianceIp -match "10.222") {
                    $TeleworkerGatewayLanIP = $VLAN.applianceIp
                }
            }
            # We only care about Meraki TeleworkerGateways
            if ($networkDevice.model.StartsWith("Z")) {
                $TeleworkerGatewayName = $networkDevice.name

                $clientName = "Meraki_${networkName}_$TeleworkerGatewayName"
                $clientIP = $TeleworkerGatewayLanIP

                $TeleworkerGateway = @{
                    "name" = $clientName
                    "ip" = $clientIP
                }                    
                
                $TeleworkerGateways += $TeleworkerGateway
            
            }
        }

    }

    return $TeleworkerGateways
}