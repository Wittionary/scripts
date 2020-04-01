<#
Write a script that gets all users that are on a litigation hold, return their legal name,
user name, mailbox UPN, and - if possible - date it was placed on hold, outputs to a CSV,
and send an email to legal team with the CSV attached on a monthly basis.
Also script the removal of litigation holds (send email to legal team to notify of as well?)
#>

# Connect O365
$TenantUname = "pvl_wallen@nsm-seating.com"
$TenantPass = cat "E:\creds\pvl_wallen.txt" | ConvertTo-SecureString
$TenantCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $TenantUname, $TenantPass

# $UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $TenantCredentials -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking

# gets all users that are on a litigation hold
# return their legal name, user name, mailbox UPN, and  Exchange GUID
$HoldResults = Get-Mailbox -Filter "$_.LitigationHoldEnabled -eq 'True'" | Select-Object DisplayName,UserPrincipalName,LitigationHoldDuration,ExchangeGuid | Sort-Object -Property DisplayName

# outputs to a CSV
$Filepath = "C:\Temp\"
$Filename = "Litigation-Hold-Review-Report-$(get-date -Format MM-dd-yyyy).csv"
if (!(Test-Path $Filepath)) {
    mkdir $Filepath
}

$HoldResults | Export-Csv -Path "$Filepath$Filename" -NoTypeInformation

# send an email to legal team with the CSV attached
$SmtpServer = "NSMEXCH01.wnsm.local"
#$EmailRecipients = "Matukewicz, Jeff <jeff.matukewicz@nsm-seating.com>","Rains, Aspen <Aspen.Rains@nsm-seating.com>","Lovett, Emily <Emily.Lovett@nsm-seating.com>"
$EmailRecipients = "Witt Allen <witt.allen@nsm-seating.com>"
$EmailSubject = "Litigation Hold Review - $(get-date -Format 'MMMM yyyy')"
$EmailReplyTo = "NSM Automation <NetOps@nsm-seating.com>"

$EmailBody = ""
$EmailBody += "Please see the attached report of users whose mailboxes are under litigation hold.`n"
$EmailBody += "`n"
$EmailBody += "- IT`n"

Send-MailMessage -From "NSM Automation <NetOps@nsm-seating.com>" -To $EmailRecipients -SmtpServer $SmtpServer -Subject $EmailSubject `
-Body $EmailBody -ReplyTo $EmailReplyTo -Attachments "$Filepath$Filename" -Verbose

# setup scheduled task to email on a regular basis

# Disconnect from O365
Remove-PSSession $Session