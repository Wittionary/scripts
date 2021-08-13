#Connect-AzAccount
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({$_ -match ".*@.*\.[a-zA-Z]{2,}"})] # Takes the form of an email address
    $SendingUserUPN,

    [Parameter(Mandatory=$true)]
    [ValidateScript({$_ -match ".*@.*\.[a-zA-Z]{2,}"})]
    $ReceivingUserUPN,

    [bool]
    $RemoveSendingPermissions = $false
)

$SendingUserID = (Get-AzADUser -UserPrincipalName $SendingUserUPN).id
$ReceivingUserID = (Get-AzADUser -UserPrincipalName $ReceivingUserUPN).id
if (($null -eq $SendingUserID) -or ($null -eq $ReceivingUserID)) {
    Write-Error "User(s) don't exist."
    break
}


$Subs = Get-AzSubscription
$SubScopes = @()
foreach ($Sub in $Subs) {  
	$SubScopes += "/subscriptions/$($Sub.id)"
}

# Get role assignments in all subscriptions for sending and receiving users
$SendingRoleAssignments = @()
$ReceivingRoleAssignments = @()
foreach ($SubScope in $SubScopes) {
	$SendingRoleAssignments += Get-AzRoleAssignment -ObjectId $SendingUserID -Scope $SubScope
	$ReceivingRoleAssignments += Get-AzRoleAssignment -ObjectId $ReceivingUserID -Scope $SubScope
}

$SendingRoleAssignments | Select-Object DisplayName,RoleDefinitionName,Scope
$ReceivingRoleAssignments | Select-Object DisplayName,RoleDefinitionName,Scope

# Apply the role assignments from sending user to receiving user
Write-Host "Copying permissions to receiving user"
foreach ($SendingRoleAssignment in $SendingRoleAssignments) {
    New-AzRoleAssignment -ObjectId $ReceivingUserID -Scope $SendingRoleAssignment.Scope `
        -RoleDefinitionName $SendingRoleAssignment.RoleDefinitionName -Verbose
}

# Remove permissions from the sending user
if ($RemoveSendingPermissions) {
    $FilePath = "C:\Users\$env:USERNAME\Downloads\Azure-permission-change-$(Get-date -Format yyyy-MM-dd_HH-mm-ss).log"
    Write-Host "Dumping sending role assignments to $FilePath"
    $SendingRoleAssignments | Out-File $FilePath -Force
    
    Write-Host "Removing permissions from $SendingUserUPN"
    foreach ($SendingRoleAssignment in $SendingRoleAssignments) {
        $SendingRoleAssignment | Remove-AzRoleAssignment -Verbose
    }
}