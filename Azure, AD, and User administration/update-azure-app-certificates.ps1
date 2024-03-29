param (
    [Parameter(Mandatory=$true)]
    $SubjectName,

    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    $PfxFilePath,

    [Parameter(Mandatory=$true)]
    [string] # Not SecureString per docs
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
    Write-Host "Context is $($AzContext.Name) ------------------------"

    # Get all the web app certs
    $WebAppCertificates = Get-AzWebAppCertificate
    Write-Host "Web app certificate count: $($WebAppCertificates.Count)"

    # Narrow it down to just expired ones
    $ExpiredCerts = $WebAppCertificates | Where-Object {$_.ExpirationDate -lt (get-date)}
    Write-Host "Expired certificate count: $($ExpiredCerts.Count)"

    # Narrow it down further to ones we've got the PFX for
    $RelevantCerts = $ExpiredCerts | Where-Object {$_.SubjectName -match $SubjectName}
    Write-Host "Relevant certificate count: $($RelevantCerts.Count)"
    if ($RelevantCerts.Count -gt 0) {
        Write-Host "Relevant cert thumbprints:`n$($RelevantCerts.Thumbprint)"

        # Get all web apps
        $WebApps = Get-AzWebApp
        Write-Host "Web apps: $($WebApps.Count)"

        # Iterate through web apps
        foreach ($WebApp in $WebApps) {
            $ThumbprintsMatch = $null
            # Compares multiples thumbprints of SSL bindings to thumbprints of relevant certs
            $SSLBindings = Get-AzWebAppSSLBinding -ResourceGroupName $WebApp.ResourceGroup -WebAppName $WebApp.Name
            if (($null -ne $SSLBindings) -and ($SSLBindings -ne "")) {
                $ThumbprintsMatch = Compare-Object -ReferenceObject $SSLBindings.Thumbprint `
                -DifferenceObject $RelevantCerts.Thumbprint -IncludeEqual -ExcludeDifferent -ErrorAction SilentlyContinue
            } else {
                Write-Host "No SSL bindings found for $($WebApp.Name)"
            }
            

            # If there's an overlap in thumbprints, then you have the right object
            if (($null -ne $ThumbprintsMatch) -and ($ThumbprintsMatch -ne "")) {
                Write-Host "Thumbprints match: $ThumbprintsMatch"
                # Find web app SSL bindings we need to update
                $WebAppSSLBindings = Get-AzWebAppSSLBinding -WebApp $WebApp

                # If it has at least one binding, continue
                if (($null -ne $WebAppSSLBindings) -and ($WebAppSSLBindings -ne "")) {
                    # Create a new binding for each existing one
                    Write-Host "Creating new SSL bindings ($($WebAppSSLBindings.Count)) for app `"$($WebApp.RepositorySiteName)`""
                    foreach ($WebAppSSLBinding in $WebAppSSLBindings) {
                        try {
                            # Remove expired binding
                            Remove-AzWebAppSSLBinding -WebApp $WebApp -Name $WebAppSSLBinding.Name -DeleteCertificate $true -Force -Verbose
                            
                            # Replace with new one
                            New-AzWebAppSSLBinding -WebApp $WebApp `
                                -CertificateFilePath $PfxFilePath `
                                -CertificatePassword $PfxPassword -SslState $WebAppSSLBinding.SslState `
                                -Name $WebAppSSLBinding.Name -Verbose
                        } catch {
                            Write-Error "Web app SSL binding:`n$($WebAppSSLBinding.SslState)"
                        }
                    }  
                    
                    # Remove expired bindings
                    <#
                    Write-Host "Removing SSL bindings that are expired"
                    foreach ($WebAppSSLBinding in $WebAppSSLBindings) {
                        try {
                            Remove-AzWebAppSSLBinding -ResourceGroupName $WebApp.ResourceGroup -WebAppName $WebApp.Name `
                                -Name $WebAppSSLBinding.Name -Verbose
                        } catch {
                            Write-Error "Web app SSL binding:`n$($WebAppSSLBinding.SslState)"
                        }
                    } 
                    #>
                }
            }
        }
    }

    
}
Disconnect-AzAccount