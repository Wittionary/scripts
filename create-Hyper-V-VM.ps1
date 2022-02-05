# DESCRIPTION:
# Deploy a virtual machine to Hyper-V 

# DOCS:
# https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-machine-in-hyper-v

# ---- CREATE THE ACTUAL VM
# Where?
# CPU, RAM, Storage (defaults: 2 vCPU, 8192 MB RAM, 100GB on C drive)
param(
    [Parameter(Mandatory=$true,Position=1)][string]$VmName,
    [string]$VmNotes,    
    [ValidateScript({Test-NetConnection $_})][string]$ClusterServer = "hyperv-cluster.domain.local",
    [ValidateRange(1,4)][int]$VmCpu = 2,
    [Int64]$VmRam = 8192MB,
    [UInt64]$VhdSize = 100GB,
    [array]$DiskLetters = @("C"),
    [Parameter(Mandatory=$true)][string]$SynologyNode
)

# TODO: Add VM name validation. e.g. Does it start with CHA, FRA, TPN etc.
# Force it to be uppercase

<#
Valid disk letters. Add to help info?
C - Operating System
D - Data
S - Software/Apps
L - Logs
T - TempDB (SQL Only)
I - Image
#>

$VmBootDevice = "CD"
$VmPath = "C:\ClusterStorage\$SynologyNode\hyper-v\vms\$VMname"
$VhdPath = "C:\ClusterStorage\$SynologyNode\hyper-v\vhdx\$VmName\"
$Iso = "C:\ClusterStorage\$SynologyNode\images\S2K19DC\s2k19dc-09222019.iso"

foreach ($DiskLetter in $DiskLetters) {
    $DiskLetter = $DiskLetter[0]
    $DiskLetter = $DiskLetter.ToUpper()
    $VhdFile = "$VmName-$DiskLetter.vhdx"
    $VhdFullPath = $VhdPath + $VhdFile

    $VhdFullPaths += $VhdFullPath
}


# Start running cmdlets on the cluster server to create needed
Invoke-Command -ComputerName $ClusterServer -ScriptBlock {
    Param($VmName,$VmPath,$VmRam,$VhdFullPaths,$VhdSize,$VmCpu,$VmNotes,$VmBootDevice,$Iso)
    # Network
    $VmSwitches = (Get-VMSwitch).name
    $VmSwitch = Get-Random $VmSwitches

    New-VM -Name $VmName -Path $VmPath -MemoryStartupBytes $VmRam -BootDevice $VmBootDevice -Generation 2
    Set-VM -Name $VmName -ProcessorCount $VmCpu -AutomaticStartAction Start -Notes $VmNotes
    Add-VMNetworkAdapter -VMName $VmName -SwitchName $VmSwitch

    Foreach ($VhdFullPath in $VhdFullPaths) { # This isn't making the second disk; not sure why yet.
        New-VHD -Path $VhdFullPath -SizeBytes $VhdSize -Dynamic
        Add-VMHardDiskDrive -VMName $VmName -Path $VhdFullPath
    }

    Disable-VMIntegrationService -Name "Time Synchronization" -VMName $VmName
    Enable-VMIntegrationService -Name "Guest Service Interface","Heartbeat","Key-Value Pair Exchange","Shutdown","VSS" `
                                -VMName $VmName
    Add-ClusterVirtualMachineRole -Name $VmName -VMName $VmName # This appears to work only when run directly on the host/cluster
    Set-VMDvdDrive -VMName $VmName -Path $Iso
    Start-VM -Name $VmName
} -ArgumentList $VmName,$VmPath,$VmRam,$VhdFullPaths,$VhdSize,$VmCpu,$VmNotes,$VmBootDevice,$Iso

#To delete VM
function Destroy-VM {
    Invoke-Command -ComputerName $ClusterServer -ScriptBlock {
        Param($VmName,$VmPath,$VhdFullPaths)
        Stop-VM -Name $VmName -Confirm:$false
        Remove-VM -Name $VmName -Confirm:$false
        Remove-ClusterGroup -Name $VmName -RemoveResources -Confirm:$false
        Remove-Item $VmPath -Force -Recurse

        Foreach ($VhdFullPath in $VhdFullPaths) {
            Remove-Item $VhdFullPath -Force -Recurse
        }
    } -ArgumentList $VmName,$VmPath,$VhdFullPaths
}


# ---- AFTER YOU CAN BOOT TO OS
# Disconnect/eject CD/DVD drive with ISO
# Change PC name to VM name
# Connect to domain
# Run Windows updates
# Install roles
# Install and configure core applications (SQL, MSMQ etc.)
# Install 3rd party apps and agents (asset management agent, monitoring agent, screenconnect agent etc.)

# ---- HEALTHCHECKS
# Can access key servers
# Can access cloud services (O365, AlientVault, logging etc.)
# Run report on ports that are open