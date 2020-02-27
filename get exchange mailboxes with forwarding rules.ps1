# https://www.slipstick.com/exchange/prevent-users-from-forwarding-mail-to-internet-addresses/
$mailboxes = Get-Mailbox -ResultSize unlimited

$forwardingRules = @()

foreach ($mailbox in $mailboxes){
    $rules = Get-InboxRule -mailbox $mailbox.id

    foreach ($rule in $rules){
        if ($null -ne $rule.forwardto){
            $forwardingRules += $rule
        }
    }
}

$forwardingRules | Select-Object -Property * | Export-Csv "Mailboxes-with-forwarding-rules-$(get-date -Format MM-dd-yyyy).csv"
