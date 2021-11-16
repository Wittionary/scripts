<# DESCRIPTION:
1. Take a host offline and out of production safely for hardware maintenance
2. Bring a host back up and put into produciton
#>
Connect-VIServer

function Start-ESXiShutdown {
    param (
        [Parameter(Mandatory=$true)]
        [ValidatePattern("^regex of hosts$")]
        $VMHost,

        $Powerdown = $true
    )

    Write-Host "Setting maintenance mode on $VMHost"
    Get-VMHost -Name $VMHost | Set-VMhost -State Maintenance

    $VMsToMigrate = Get-VM | Where-Object {$_.VMHost -match $VMHost}
    Write-Host "$($VMsToMigrate.Count) VMs pending vMotion"
    $DestinationHosts = Get-VMHost | Where-Object {$_.Name -notmatch $VMHost}

    $VMsMigrated = 0
    foreach ($VMToMigrate in $VMsToMigrate) {
        # Select a random host to move to
        Move-VM -VM $VMToMigrate -Destination (Get-Random $DestinationHosts)
        $VMsMigrated++
    }
    Write-Host "$VMsMigrated VMs migrated"

    if ($Powerdown = $true) {
        Stop-VMHost -VMHost $VMHost
    }
}

function Bring-ESXiOnline {
    param (
        [Parameter(Mandatory=$true)]
        [ValidatePattern("^regex of hosts$")]
        $VMHost,

        $ReceiveVMs = $true
    )

    # unset maintenance mode
    # get 1/3rd of VMs on either host
    $OnlineHosts = Get-VMHost | Where-Object {$_.State -match "Connected"}
    $VMs = Get-VM
    # vMotion to online host
}