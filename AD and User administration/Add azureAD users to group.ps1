# Add all AzureAD Users to a group
param (
    $GroupName = "Name of Group"
)
Import-Module Azuread
Connect-AzureAD

$Group = Get-AzureADGroup -SearchString $GroupName
$Users = Get-AzureADUser -All $true

foreach ($User in $Users) {
    Add-AzureADGroupMember -ObjectId $Group.ObjectId -RefObjectId $User.ObjectId
}