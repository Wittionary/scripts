param($vSphereServer,$vSphereAdmin,$CredentialPath,$LocalDomain)
Install-Module vmware.powercli
Import-Module vmware.powercli
Set-PowerCLIConfiguration -scope User -participateinCEIP $false -InvalidCertificateAction Ignore -Confirm:$false

function Renew-VMHostVMCACertificate {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Array]$ESXiHosts = (Get-VMHost | Where-Object {($_.ConnectionState -eq "Connected") -and ($_.PowerState -eq "PoweredOn")} | Select-Object -Property Name)
    )

    $ESXiHost = Get-Random $ESXiHosts

    $hostid = Get-VMHost $ESXiHost.Name | Get-View
    $hostParam = New-Object VMware.Vim.ManagedObjectReference[] (1)
    $hostParam[0] = New-Object VMware.Vim.ManagedObjectReference
    $hostParam[0].value = $hostid.moref.value
    $hostParam[0].type = 'HostSystem'
    $_this = Get-View -Id 'CertificateManager-certificateManager'
    $_this.CertMgrRefreshCertificates_Task($hostParam)
}

# Format username to include the local domain if it doesn't already
if ($vSphereAdmin -match $LocalDomain) {
    $vSphereUsername = $vSphereAdmin
} else {
    $vSphereUsername = "$($vSphereAdmin)@$LocalDomain"
}

$vSpherePassword = Get-Content $CredentialPath | ConvertTo-SecureString
$vSphereCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $vSphereUsername, $vSpherePassword

Write-Host "Connecting as $vSphereUsername..."
Connect-VIServer -Server $vSphereServer -Credential $vSphereCreds
Renew-VMHostVMCACertificate