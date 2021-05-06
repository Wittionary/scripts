param(
    $GroupName = "*"
)

Connect-ExchangeOnline

$AllMailboxes = Get-EXOMailbox -ResultSize Unlimited -PropertySets All
$HiddenMailboxes = $AllMailboxes | Where {$_.HiddenFromAddressListsEnabled -eq $True}
Write-Host "Hidden mailbox count: $($HiddenMailboxes.Count)"

foreach ($HiddenMailbox in $HiddenMailboxes) {
    # Can limit which ones to unhide by group membership
    if ((Get-ADPrincipalGroupMembership -Identity $HiddenMailbox.alias -ea SilentlyContinue | Where-Object {$_.name -eq $GroupName})) {
         # then unhide
         Set-RemoteMailbox $HiddenMailbox.Id -HiddenFromAddressListsEnabled $false
    }
}