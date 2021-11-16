Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Ctrl + C to exit script
while ($true) {
    $FullName = (Read-Host "Full name").Trim()
    $FirstName = $FullName.Split(" ")[0]
    $LastName = $FullName.Split(" ")[1]
    $InactiveMailbox = $null

    $InactiveMailbox = Get-EXOMailbox -InactiveMailboxOnly -Identity "$FirstName.$LastName@domain.net" -ErrorAction SilentlyContinue
    if ($null -eq $InactiveMailbox) {
        $InactiveMailbox = Get-EXOMailbox -InactiveMailboxOnly -Identity "$($FirstName[0])$LastName@domain.net" -ErrorAction SilentlyContinue
    }
    if ($null -eq $InactiveMailbox) {
        $InactiveMailbox = Get-EXOMailbox -InactiveMailboxOnly -Identity "$($FirstName[0]).$LastName@domain.net" -ErrorAction SilentlyContinue
    }

    if ($null -ne $InactiveMailbox) {
        try {
            New-Mailbox -InactiveMailbox $InactiveMailbox.DistinguishedName -Name "$FirstName $LastName" -FirstName $FirstName `
            -LastName $LastName -DisplayName "RECOVERED $FirstName $LastName" -MicrosoftOnlineServicesID $InactiveMailbox.UserPrincipalName `
            -Password (ConvertTo-SecureString -String (Get-Date -Format mmMMM!ssddzxyy) -AsPlainText -Force) -ResetPasswordOnNextLogon $true
            Write-Host "SUCCESS - Recovered mailbox $($InactiveMailbox.UserPrincipalName)"
        }
        catch {
            Write-Error "The mailbox `"$($InactiveMailbox.UserPrincipalName)`" was found, but could not be recovered for $FirstName $LastName because there was an error"
        }
        <#
            grant 365F3 license,
            wait for mailbox to be made,
            convert to shared mailbox,
            wait for that conversion process to complete,
            hide from GAL,
            add aspen rains to it,
            remove 365F3 license
        #>
    } else {
        Write-Warning "Did not recover a mailbox for $FirstName $LastName"
        # Start sending back lit holds that don't have the proper spelling of names
    }
}