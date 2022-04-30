Param (
    $SearchString = "adfs01.domain.tld" # FQDN
)

Connect-AzureAd
$Apps = Get-AzureADApplication -all $true


$AppsReferencingOnpremADFS = @()
foreach ($App in $Apps) {

    if (($App.ReplyUrls -match $SearchString) -or ($App.LogoutUrl -match $SearchString) -or
        ($App.IdentifierUris -match $SearchString) -or ($App.Homepage -match $SearchString) -or
        ($App.ErrorUrl -match $SearchString)) {

        $AppsReferencingOnpremADFS += $App
    }
}

Write-Host $AppsReferencingOnpremADFS