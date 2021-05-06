$DisabledADUsers = Get-ADUser -Filter {Enabled -eq $false}
$UsersWithMoreThanOneGroup = 0


foreach ($DisabledADUser in $DisabledADUsers) {
    # Everything but Domain Users groups
    $Groups = $DisabledADUser | Get-ADPrincipalGroupMembership | Where-Object {$_.name -ne "Domain Users"} | Select-Object name

    
    if ($null -ne $Groups) {
        $UsersWithMoreThanOneGroup++
        # Remove each of those groups
        foreach ($Group in $Groups) {
            try {
                Remove-ADGroupMember -Identity $Group.name -Members $DisabledADUser -Confirm:$false
            } catch {
                Write-Error "Error removing $($DisabledADUser.Name) from group $($Group.Name)."
            }
            
        }
    }
}

Write-Host "Out of $($DisabledADUsers.count) disabled users, $($UsersWithMoreThanOneGroup) had excessive groups."