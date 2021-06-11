# Fixes transaction logs not truncating per KB https://www.veeam.com/kb2027
param (
    [Array]
    $Servers = @()
)
$Locations = @("HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\", "HKLM:\SOFTWARE\Wow6432Node\Veeam\Veeam Backup and Replication\")

foreach ($Server in $Servers) {
    $Result = Invoke-Command -ComputerName $Server -ScriptBlock {
        foreach ($Location in $args) {
            if (!(Test-Path $Location)) {
                Write-Host "Creating $Location"
                New-Item $Location -Force
            }
        
            Set-Location $Location
            $SqlExecTimeoutValue = 600
            $SqlLogBackupTimeoutValue = 3600
            $SqlConnectionTimeoutValue = 300

            if (Get-ItemProperty -Path . -Name "SqlExecTimeout" -ErrorAction SilentlyContinue) {
                $RegkeyValue = $(Get-ItemProperty -Path . -Name "SqlExecTimeout").SqlExecTimeout
                if ($RegkeyValue -ne $SqlExecTimeoutValue) {
                    Set-ItemProperty -Path . -Name "SqlExecTimeout" -Value $SqlExecTimeoutValue
                } else {
                    Write-Host "Value of $RegkeyValue is okay in $Location"
                }
            } else {
                New-ItemProperty -Path . -Name "SqlExecTimeout" -Value $SqlExecTimeoutValue -propertyType dword
            }
            
            if (Get-ItemProperty -Path . -Name "SqlLogBackupTimeout" -ErrorAction SilentlyContinue) {
                $RegkeyValue = $(Get-ItemProperty -Path . -Name "SqlLogBackupTimeout").SqlLogBackupTimeout
                if ($RegkeyValue -ne $SqlLogBackupTimeoutValue) {
                    Set-ItemProperty -Path . -Name "SqlLogBackupTimeout" -Value $SqlLogBackupTimeoutValue
                } else {
                    Write-Host "Value of $RegkeyValue is okay in $Location"
                }
            } else {
                New-ItemProperty -Path . -Name "SqlLogBackupTimeout" -Value $SqlLogBackupTimeoutValue -propertyType dword
            }
            
            if (Get-ItemProperty -Path . -Name "SqlConnectionTimeout" -ErrorAction SilentlyContinue) {
                $RegkeyValue = $(Get-ItemProperty -Path . -Name "SqlConnectionTimeout").SqlConnectionTimeout
                if ($RegkeyValue -ne $SqlConnectionTimeoutValue) {
                    Set-ItemProperty -Path . -Name "SqlConnectionTimeout" -Value $SqlConnectionTimeoutValue
                } else {
                    Write-Host "Value of $RegkeyValue is okay in $Location"
                }
            } else {
                New-ItemProperty -Path . -Name "SqlConnectionTimeout" -Value $SqlConnectionTimeoutValue -propertyType dword
            }
        }
    } -ArgumentList $Locations
    Write-Host "$Server results:`n$Result"
}
