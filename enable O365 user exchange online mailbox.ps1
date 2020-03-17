param($Identity, $ExchangeServer)

$Credentials = Get-Credential

# Get connected to the on-prem Exchange server
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer/PowerShell/ -Authentication Kerberos -Credential $Credentials
Import-PSSession $Session

# Enable the user's mailbox for Exchange Online
Enable-RemoteMailbox -Identity $Identity