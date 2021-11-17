$TestVm1 = "server01"
$TestVm2 = "server02"
$Vmhost = "esxi01.domain.local"
$vibPath = ""

# Initial state with versions
Get-vmhost | Select-Object Name,Version,Build,PowerState,State,ConnectionState,LicenseKey

# Put a host in maintenance mode and remove VMs
# https://pubs.vmware.com/vsphere-51/index.jsp?topic=%2Fcom.vmware.powercli.cmdletref.doc%2FSet-VMHost.html
Set-VMHost -VMHost $Vmhost -State Maintenance -Evacuate:$true

# Confirm the host has been fully evacuated; the following should return 0 VMs
Get-vmhost $Vmhost | Get-VM
# If it hasn't, wait some time and check again

# Update host
Get-vmhost $Vmhost | Install-VMHostPatch -HostPath $vibPath
# Via VUM?

# Reboot the host

# Set host to Connected state
Set-VMHost -VMHost $Vmhost -State Connected -Evacuate:$true

# Migrate a couple VMs to it
Move-VM $TestVm1 -Destination $Vmhost
Move-VM $TestVm2 -Destination $Vmhost

# Verify VMs are up and running
Sleep -s 15
$Result1 = Test-NetConnection $TestVm1 -InformationLevel Quiet
$Result2 = Test-NetConnection $TestVm2 -InformationLevel Quiet

# Repeat for other two hosts