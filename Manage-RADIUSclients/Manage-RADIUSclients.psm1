<#
This module is to assist in managing RADIUS clients properly. 
It will take action (Add, update, remove) for each client against every RADIUS server. Currently:
$RadiusServers = @("TPN-702-NPS01.wnsm.local","CHA-704-NPS01.wnsm.local","TPCD-701-NPS01.wnsm.local")

TODO: If it fails to add to either server, it will error out, notify the user, and attempt to remove the successful entry if
it was only successful on one.

Don't forget to use the Meraki module in combination with this one:
Import-Module -Name C:\Users\james.allen\Documents\git\Manage-RadiusClients\NSM-Meraki-API.psm1
$RadiusClients = Get-MerakiAPs
#>
#$SharedSecret = 'Never store credentials in code'

function Add-RadiusClients {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Clients = $RadiusClients,

        [Parameter(Mandatory=$true)]
        [Array]$Servers = $RadiusServers,

        [Parameter(Mandatory=$true)]
        [String]$SharedSecret
    )
 
    # Enumerate through each desired Radius client
    foreach ($Client in $Clients) {

        foreach ($Server in $Servers) {
            # Make the change on each server. TODO: Capture if it was successful
            Invoke-Command -ComputerName $Server -ScriptBlock {
                try {
                    New-NpsRadiusClient -name $args[0].name -address $args[0].ip -SharedSecret $args[1]
                }
                catch [System.ArgumentException] {
                    Write-Error "The RADIUS client already exists."
                    
                    Write-Verbose "See if the IP address needs to be updated for this client."
                    $ExistingRadiusClients = Get-NpsRadiusClient
                    foreach ($ExistingRadiusClient in $ExistingRadiusClients) {
                        if (($args[0].name -eq $ExistingRadiusClient.name) -and
                            ($args[0].ip -ne $ExistingRadiusClient.address)) {
                                Write-Verbose "Setting $($args[0].name) from $($args[0].ip) to $($ExistingRadiusClient.address)"
                                Set-NpsRadiusClient -name $args[0].name -Address $ExistingRadiusClient.address
                        }
                    }
                }
            } -ArgumentList $Client,$SharedSecret

            # If everything was successful, do nothing.
            # TODO: Else undo the addition of the Radius client on the successful servers.
        }
    }

    #Write-Debug "Success: $($successfulAdditions.Count)`nFailed: $($failedAdditions.Count)"
    #Write-Debug "Exit codes: "($exitCodes)
    Write-Debug "RadiusClients count: $($Clients.Count)"
    Write-Debug "RadiusClients: $($Clients)"
}

function Update-SharedSecret {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSObject]$Clients = $RadiusClients,

        [Parameter(Mandatory=$true)]
        [Array]$Servers = $RadiusServers,

        [Parameter(Mandatory=$true)]
        [String]$SharedSecret
    )

        # Enumerate through each desired Radius client
        foreach ($Client in $Clients) {

            foreach ($Server in $Servers) {
                # Make the change on each server. TODO: Capture if it was successful
                Invoke-Command -ComputerName $Server -ScriptBlock {
                    Set-NpsRadiusClient -name $args[0].name -SharedSecret $args[1]
                } -ArgumentList $Client,$SharedSecret
    
                # If everything was successful, do nothing.
                # TODO: Else undo the addition of the Radius client on the successful servers.
            }
        }
        return 0
}

function Update-IPAddress {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSObject]$Clients = $RadiusClients,

        [Parameter(Mandatory=$true)]
        [Array]$Servers = $RadiusServers,

        [Parameter(Mandatory=$true)]
        [String]$Address
    )

        # Enumerate through each desired Radius client
        foreach ($Client in $Clients) {

            foreach ($Server in $Servers) {
                # Make the change on each server. TODO: Capture if it was successful
                Invoke-Command -ComputerName $Server -ScriptBlock {
                    Set-NpsRadiusClient -name $args[0].name -Address $args[1]
                } -ArgumentList $Client,$Address
    
                # If everything was successful, do nothing.
                # TODO: Else undo the edit of the Radius client on the successful servers.
            }
        }
        return 0
}

function Update-Enabled {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSObject]$Clients = $RadiusClients,

        [Parameter(Mandatory=$true)]
        [Array]$Servers = $RadiusServers,

        [Parameter(Mandatory=$true)]
        [Boolean]$Enabled
    )

        # Enumerate through each desired Radius client
        foreach ($Client in $Clients) {

            foreach ($Server in $Servers) {
                # Make the change on each server. TODO: Capture if it was successful
                Invoke-Command -ComputerName $Server -ScriptBlock {
                    Set-NpsRadiusClient -name $args[0].name -Enabled $args[1]
                } -ArgumentList $Client,$Enabled
    
                # If everything was successful, do nothing.
                # TODO: Else undo the edit of the Radius client on the successful servers.
            }
        }
        return 0
}


# ---- We only need to pass Radius client names (or patterns) to remove
function Remove-RadiusClients {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSObject]$Clients = $RadiusClients,

        # [WildcardPattern]$Pattern = "",

        [Parameter(Mandatory=$true)]
        [Array]$Servers = $RadiusServers
    )

    # Enumerate through each desired Radius client
    foreach ($Client in $Clients) {

        foreach ($Server in $Servers) {
            # Make the change on each server. TODO: Capture if it was successful
            Invoke-Command -ComputerName $Server -ScriptBlock {
                Remove-NpsRadiusClient -name $args[0].name
            } -ArgumentList $Client

            # If everything was successful, do nothing.
            # TODO: Else undo the addition of the Radius client on the successful servers.
        }
    }
    return 0
}
# Script should notify sysadmin distro what exactly happened upon runtime:
# whether success (after confidence is built, Success case will be removed),
# partial success, or total failure.