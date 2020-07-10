# Add DOMAIN\sAMAccountName to user attribute
Import-Module ActiveDirectory

$Domain = (Get-ADDomain).forest
$ADGroup = Get-ADGroup -Filter {Name -like "*SERVICEDESK*"}

# Users that are enabled and haven't already been configured with that attribute
$Users = Get-ADUser -Filter {(Enabled -eq 'True') -and (extensionAttribute15 -notlike "*")}
ForEach ($User in $Users) {
	Write-Verbose "Changing extensionAttribute15 for the user $($User.sAMAccountName)"
    $User.extensionAttribute15=$Domain.ToUpper() + "\" + $User.SamAccountName
    Set-ADUser -Instance $User

    Write-Verbose "Adding user $($User.sAMAccountName) to group $($ADGroup.name)"
    Add-ADGroupMember -Identity $ADGroup.name  -Members $User
}