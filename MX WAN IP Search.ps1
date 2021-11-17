function Get-MerakiAPs(){
    # Ensures that Invoke-WebRequest uses TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Declare variables
    $api = @{
        "endpoint" = 'https://api.meraki.com/api/v0'
        "key" = 'your actual API key go here' # TODO: pass in API key via config file
        }
    $header = @{
            "X-Cisco-Meraki-API-Key" = $api.key
            "Content-Type" = 'application/json'
        }
    $orgID = 1234567 # Can be obtained via Meraki UI or API call
    $AccessPoints = @()

    # Get all networks
    $api.url = "/organizations/$orgID/networks"
    $uri = $api.endpoint + $api.url
    $networks = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json

    # Enumerate through each network
    foreach ($network in $networks) {
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