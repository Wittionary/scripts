<#
Write a script that gets all users that are on a litigation hold, return their legal name,
user name, mailbox UPN, and - if possible - date it was placed on hold, outputs to a CSV,
and send an email to legal team with the CSV attached on a monthly basis.
Also script the removal of litigation holds (send email to legal team to notify of as well?)
#>
# There is a scheduled task with a service account that kicks this off on the first Tuesday of every month.

# Connect O365
$TenantUname = "azure_svc@domain.tld"
$TenantPass = cat "C:\creds\azure_svc.txt" | ConvertTo-SecureString
$TenantCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $TenantUname, $TenantPass

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
$SmtpServer = "SMTP01.domain.tld"
$EmailRecipients = "First Last <first.last@domain.tld>","User2 <user2@domain.tld>"
$EmailSubject = "Litigation Hold Review - $(get-date -Format 'MMMM yyyy')"
$EmailFrom = "Automation Account <automation@domain.tld>"

$EmailBody = ""
$EmailBody += "Please see the attached report of users whose mailboxes are under litigation hold.`n"
$EmailBody += "`n"
$EmailBody += "- IT`n"

Send-MailMessage -From $EmailFrom -To $EmailRecipients -SmtpServer $SmtpServer -Subject $EmailSubject `
-Body $EmailBody -Attachments "$Filepath$Filename" -Verbose

# Delete export
Remove-Item -Path "$Filepath$Filename" -Force -Confirm:$false

# Disconnect from O365
Remove-PSSession $Session