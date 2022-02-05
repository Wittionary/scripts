# Move FRA office APs to RADIUS servers


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
# We only care about the Franklin Hub for testing
$networks = $networks | Where-Object {$_.name -eq "test-network-name"}

# Enumerate through each network
foreach ($network in $networks) {
    $networkID = $network.id
    $networkName = $network.name

    # ----------------- Receive input of location; see break statement at end of script

    # ----------------- Get every SSID for a location/branch
    # https://developer.cisco.com/meraki/api/#/rest/api-endpoints/ssids/get-network-ssids
    $api.url = "/networks/$networkID/ssids"
    $uri = $api.endpoint + $api.url
    $SSIDs = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json


    # Get the first Unconfigured SSID and then move along with the rest of the script
    foreach ($SSID in $SSIDs) {
        if ($SSID.name -match "Unconfigured SSID *") {
            $UnconfiguredSSID = $SSID
            break
        }
    }

    # ----------------- Configure the SSID as desired
    # https://developer.cisco.com/meraki/api/#/rest/api-endpoints/ssids/update-network-ssid
    $RequestData1 = @{        
        name = "Unconfigured SSID WITT";
        enabled = $false;
        authMode= "8021x-radius";
        wpaEncryptionMode= "WPA2 only";
        radiusServers= @(
            @{
            host = "10.0.0.165";
            secret = "presharedkey1234";
            port = 1812;
            }
            @{
            host= "10.2.23.103";
            secret= "presharedkey1234";
            port= 1812;
            };
        );
        radiusFailoverPolicy= "Deny access";
        radiusLoadBalancingPolicy= "Round robin";
        ipAssignmentMode= "Bridge mode";
        #

    };

    $RequestData2 = @{        
        name = "Unconfigured SSID WITT";
        enabled = $false;
        ipAssignmentMode= "Bridge mode";
        useVlanTagging= $false; #$true
        defaultVlanid = 24;
        availableOnAllAps = $true;
    };

    $RequestDataNull = @{       
            name = "Unconfigured SSID 5";
            enabled = $false;
            authMode= "open";
            splashPage= "None";
            ssidAdminAccessible = $false;
            radiusServers= $null;
            ipAssignmentMode= "NAT mode";
            defaultVlanid = $null;
            minBitrate = 11;
            bandSelection = "Dual band operation";
            perClientBandwidthLimitUp = 0;
            perClientBandwidthLimitDown = 0;
            visible = $True;
            availableOnAllAps = $True;
            availabilityTags = @();
        };
    $RequestBody1 = $RequestData1 | ConvertTo-Json;
    $RequestBody2 = $RequestData2 | ConvertTo-Json;
    $RequestBody = $RequestDataNull | ConvertTo-Json;

    $api.url = "/networks/$networkID/ssids/4" #$($UnconfiguredSSID.number)
    $uri = $api.endpoint + $api.url
    # GET
    $ConfigSSIDResponseGet = Invoke-WebRequest -Uri $uri -Method GET -Headers $header | ConvertFrom-Json
    # PUT
    $ConfigSSIDResponsePut = Invoke-WebRequest -Uri $uri -Method PUT -Headers $header -Body $RequestBody1 | ConvertFrom-Json
    $ConfigSSIDResponsePut = Invoke-WebRequest -Uri $uri -Method PUT -Headers $header -Body $RequestBody2 | ConvertFrom-Json
    
    # This is the network we want to modify. Once we're ready to change all networks, take out this break statement.
}
