param (
    [Parameter(Mandatory=$true)]
    $SubjectName,

    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    $PfxFilePath,

    [Parameter(Mandatory=$true)]
    [securestring]
    $PfxPassword,

    [switch]
    $AllSubscriptions = $false
)
# This fixes trying to regex match with wildcard certs
if ($SubjectName.StartsWith("*")) {
    $SubjectName = ".$SubjectName"
}

Import-Module az
Connect-AzAccount
if ($AllSubscriptions) {
    # Update across all subscriptions
    $AzContexts = Get-AzContext -ListAvailable
} else {
    # Attempt to set to a "test" subscription
    try {
    $AzContexts = Get-AzContext -ListAvailable |
    Where-Object {$_.SubscriptionName -match "test"}
    }
    catch {
        throw "Test subscription not found. Exiting script."
    }
}

foreach ($AzContext in $AzContexts)  {
    Set-AzContext -Subscription $AzContext.Subscription

    # Get all the web app certs
    $WebAppCertificates = Get-AzWebAppCertificate
    Write-Verbose "Web app certificate count: $($WebAppCertificates.Count)"

    # Narrow it down to just expired ones
    $ExpiredCerts = $WebAppCertificates | Where-Object {$_.ExpirationDate -lt (get-date)}
    Write-Verbose "Expired certificate count: $($ExpiredCerts.Count)"

    # Narrow it down further to ones we've got the PFX for
    $RelevantCerts = $ExpiredCerts | Where-Object {$_.SubjectName -match $SubjectName}
    Write-Verbose "Relevant cert thumbprints:`n($RelevantCerts.Thumbprint)"

    # Get all web apps
    $WebApps = Get-AzWebApp

    # Iterate through web apps
    foreach ($WebApp in $WebApps) {
        # Find web app SSL bindings we need to update
        $WebAppSSLBinding = Get-AzWebAppSSLBinding -ResourceGroupName $WebApp.ResourceGroup -WebAppName $WebApp.Name |
        Where-Object {$_.Thumbprint -eq $RelevantCerts.Thumbprint}

        # If found, replace cert/binding
        if (($null -ne $WebAppSSLBinding) -and ($WebAppSSLBinding -ne "")) {
            New-AzWebAppSSLBinding -ResourceGroupName rg_nsm_fund1_qa -WebAppName NSMFundingPortalQA `
            -CertificateFilePath $PfxFilePath `
            -CertificatePassword $PfxPassword -SslState $WebAppSSLBinding.SslState `
            -Name $WebAppSSLBinding.Name -Verbose
        }
    }
}
Disconnect-AzAccount