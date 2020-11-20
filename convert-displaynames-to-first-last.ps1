$CommaDisplayNameUsers = Get-ADuser -filter * | Where {$_.name -match ","}
Write-Host "Starting 'Last, First' users: $($CommaDisplayNameUsers.count)"
# To test
#$CommaDisplayNameUsers = $CommaDisplayNameUsers | Where {$_.samAccountName -eq "your.own.samaccountname"}

foreach ($CommaDisplayNameUser in $CommaDisplayNameUsers) {
    $FirstName = $CommaDisplayNameUser.GivenName
    $LastName = $CommaDisplayNameUser.Surname
    $DisplayName = "$FirstName $LastName"

    $ADUserProperties = @{
        DisplayName = $DisplayName;
    }

    # Changes Display Name
    Set-ADUser -Identity $CommaDisplayNameUser.samAccountName -Replace $ADUserProperties
}

$CommaDisplayNameUsers = Get-ADuser -filter * | Where {$_.name -match ","}
Write-Host "Ending 'Last, First' users: $($CommaDisplayNameUsers.count)"