Import-Module ExchangeOnlineManagement
Connect-IPPSSession -UserPrincipalName "pvl_wallen@domain.com"

$UsersFromClipboard = ""

$EmailAddresses = "user@domain.com"


$NotifyEmail = "me@domain.com"
$Description = "Created by $env:USERNAME via script on $(Get-Date)"
$CaseName = "user 11-6-2020"

# Make the case when it doesn't exist
if ($null -eq (Get-ComplianceCase $CaseName)) {
    Write-Host "Case `"$CaseName`" not found. Making case."
    New-ComplianceCase $CaseName
}

foreach ($EmailAddress in $EmailAddresses) {
    # Run a different search for each mailbox to minimize PST overhead
    $SearchName = "$(($EmailAddress.split("@"))[0]) $(get-date -Format MM-dd-yyyy)"
    New-ComplianceSearch -Case $CaseName -Name $SearchName `
    -ContentMatchQuery "(c:c)(date=2020-01-01..2020-10-23)" -Description $Description `
    -ExchangeLocation $EmailAddress

    $ComplianceSearch = Get-ComplianceSearch -Case $CaseName -Identity $SearchName
    while ($ComplianceSearch.Status -eq "NotStarted") {
        Write-Host "Waiting to start search for $EmailAddress..."
        Start-Sleep -s 10
        Start-ComplianceSearch -Identity $SearchName
        $ComplianceSearch = Get-ComplianceSearch -Case $CaseName -Identity $SearchName
        Write-Host "Compliance search status: $($ComplianceSearch.Status)"
    }
    
}


foreach ($EmailAddress in $EmailAddresses) {
    $ComplianceSearch = Get-ComplianceSearch -Case $CaseName -Identity $SearchName
    while ($ComplianceSearch.Status -ne "Completed") {
        Write-Host "Waiting to initiate export for $SearchName..."
        Start-Sleep -s (60*1)
        $ComplianceSearch = Get-ComplianceSearch -Case $CaseName -Identity $SearchName
        Write-Host "Compliance search status: $($ComplianceSearch.Status)"
    }

    Write-Host "Initiating export $EmailAddress"
    $ActionResult = New-ComplianceSearchAction -SearchName $SearchName -Export -ExchangeArchiveFormat SinglePst `
    -NotifyEmail $NotifyEmail -scope IndexedItemsOnly -Format FxStream
    Write-Host "$ActionResult"
}

