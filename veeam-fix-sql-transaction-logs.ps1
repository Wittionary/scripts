# Fixes transaction logs not truncating per KB https://www.veeam.com/kb2027
param (
    [Array]
    $Servers = @()
)
$Locations = @("HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\", "HKLM:\SOFTWARE\Wow6432Node\Veeam\Veeam Backup and Replication\")

foreach ($Server in $Servers) {
    $Result = Invoke-Command -ComputerName $Server -ScriptBlock {
        foreach ($Location in $args[0]) {
            if (!(Test-Path $Location)) {
                Write-Host "Creating $Location"
                New-Item $Location -Force
            }
        
            Set-Location $Location
            try {New-ItemProperty . -Name "SqlExecTimeout" -Value 600 -propertyType dword}
            catch {Set-ItemProperty . -Name "SqlExecTimeout" -Value 600}
            try {New-ItemProperty . -Name "SqlLogBackupTimeout" -Value 3600 -propertyType dword}
            catch {Set-ItemProperty . -Name "SqlLogBackupTimeout" -Value 3600}
            try {New-ItemProperty . -Name "SqlConnectionTimeout" -Value 300 -propertyType dword}
            catch {Set-ItemProperty . -Name "SqlConnectionTimeout" -Value 300}
        }
    } -ArgumentList $Locations
    Write-Host "$Server results:`n$Result"
}
