function Renew-VMHostVMCACertificate {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Array]$ESXiHosts = (Get-VMHost | Where-Object {($_.ConnectionState -eq "Connected") -and ($_.PowerState -eq "PoweredOn")} | Select-Object -Property Name)
    )

    $ESXiHost = Get-Random $ESXiHosts

    process {
        $hostid = Get-VMHost $ESXiHost | Get-View
        $hostParam = New-Object VMware.Vim.ManagedObjectReference[] (1)
        $hostParam[0] = New-Object VMware.Vim.ManagedObjectReference
        $hostParam[0].value = $hostid.moref.value
        $hostParam[0].type = 'HostSystem'
        $_this = Get-View -Id 'CertificateManager-certificateManager'
        $_this.CertMgrRefreshCertificates_Task($hostParam)
    }
}
    