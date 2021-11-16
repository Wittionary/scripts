# DESCRIPTION:
# Take a fresh Windows Server 2019 VM and set it up as a 
# RADIUS server to authenticate against.

# RESOURCES:
# NPS cmdlets - https://docs.microsoft.com/en-us/powershell/module/nps/?view=win10-ps


# Install NPAS role (Network Policy and Access Server)
Install-WindowsFeature -Name "NPAS" -IncludeManagementTools # No restart needed

# Add to domain
Add-Computer -domainname wnsm.local -credential (Get-Credential) -restart

# https://www.risual.com/2019/03/28/windows-2019-server-nps-bug/
Start-Process cmd.exe '/k sc sidtype IAS unrestricted' -Verb runas

# Setup NPS or
# Import a config if able
$NpsConfigPath = "D:\NPS\configs\NPSconfig.xml"
$ExportServer = "CHA-704-NPS01.wnsm.local"
$ImportServers = "TPN-702-NPS01.wnsm.local","TPN-702-NPS02.wnsm.local"

# Export the good config
Invoke-Command -ComputerName $ExportServer -ScriptBlock {
    Param($NpsConfigPath)
    Export-NpsConfiguration -Path $NpsConfigPath
} -ArgumentList $NpsConfigPath

# Copy the good config to server(s) and import
foreach ($ImportServer in $ImportServers) {
    Invoke-Command -ComputerName $ImportServer -ScriptBlock {
        Param($ExportServer,$NpsConfigPath)
        Copy-Item -Path "\\${ExportServer}\D`$\NPS\configs\NPSconfig.xml" -Destination $NpsConfigPath
        Import-NpsConfiguration -Path $NpsConfigPath
        Remove-Item $NpsConfigPath -Force
    } -ArgumentList $ExportServer,$NpsConfigPath
}
# Move copy command to locally executed, UNC-to-UNC copy

# Remove the config export file from the server that exported it
Invoke-Command -ComputerName $ExportServer -ScriptBlock {
    Param($NpsConfigPath)
    Remove-Item -Path $NpsConfigPath
} -ArgumentList $NpsConfigPath

# Configure Accounting
# Register server in Active Directory
