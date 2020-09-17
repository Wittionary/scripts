param(
    $CrmUrl = 'https://nsm-marketing.crm.dynamics.com',
    $UserAddresses = @(),

    [Parameter(Mandatory = $true)]
    [SecureString]$PvlCreds
)

Install-Module Microsoft.Xrm.Data.Powershell
Import-Module Microsoft.Xrm.Data.Powershell

# This function was originally written by psn0ob on Spiceworks
# I've made some edits which I've found to be improvements
# Source: https://community.spiceworks.com/scripts/show/4292-dynamics-365-approve-a-new-user-email-address
function Enable-xCRMMailbox {

    <#
.DESCRIPTION
    Connects to the Microsoft CRM Instance and searches for the user specified, approving the email address for the user.
    Finds the associated mailbox and enables it.

    Expected output should be:

    [Success] Connect to CRM Online
    [Success] Get SystemUser ID Record
    [Success] Email Address Approved
    [Success] Get Mailbox ID Record
    [Success] Mailbox is Enabled

    Mailbox          : user@contoso.com
    UserID           : ea4bc30c-7f2b-48a8-92a1-a77e76868c54
    MailboxID        : 257f4f22-ea66-4e48-9051-1c75b929c277
    CRM URL          : https://contoso.crm6.dynamics.com
    Address Approved : Approved
    Mailbox Enabled  : Yes

.EXAMPLE

    Enable-xCRMMailbox -Mailbox user@contoso.com -CRMURL "https://contoso.crm6.dynamics.com"

.NOTES
    AUTHOR   : Andrew Beaumont
    DATE     : 2018-04-11 10:36
    MODIFIED : 2018-04-11 14:38

    #>


    param (
        [CmdletBinding()]

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Email Address of User to Enable"
        )]
        [string]$EmailAddress,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "URL of CRM instance"
        )]
        [string]$CRMURL = "https://yourCrmInstance.crm6.dynamics.com",

        $Credential
    ) # END PARAM

    # Create Reporting Object
    $outputReport = @{
        Mailbox            = $EmailAddress
        UserID             = $null
        MailboxID          = $null
        'CRM URL'          = $CRMURL
        'Address Approved' = 'False'
        'Mailflow Enabled' = 'False'
    } # END

    # Import Admin Credential
    #$CredXmlPath = Join-Path (Split-Path $Profile) admin.credential
    #$Credential = Import-CliXml $CredXmlPath
    

    # Connect to CRM Online
    try {
        $Conn = Connect-CrmOnline -Credential $Credential -ServerUrl $CRMURL -ErrorAction Stop
        Write-Output "[Success] Connect to CRM Online"
    }
    catch {
        Write-Output "[Failure] Unable to connect to CRM Online"
        $outputReport.Error = $_.exception
        Return $outputReport
    } # End Connect to CRM Online

    # Query User Record
    try {
        # Set User Query Options
        $getUserOptions = @{
            EntityLogicalName = "systemuser"
            Fields            = "systemuserid"
            FilterAttribute   = "internalemailaddress"
            FilterOperator    = "eq"
            FilterValue       = $EmailAddress
        } # End User Query Options

        # Get User Record
        $User = Get-CrmRecords @getUserOptions -ErrorAction Stop
        $outputReport.UserID = $User.CrmRecords.systemuserid
        Write-Output "[Success] Get SystemUser ID Record"

    }
    catch {
        Write-Output "[Failure] Unable to find User Record"
        $outputReport.Error = $_.exception
        Return $outputReport
    } # End Query User Record

    # Approve Email Address
    try {
        Approve-CrmEmailAddress -UserId $User.CrmRecords.systemuserid -conn $Conn -ErrorAction Stop
    }
    catch {
        Write-Output "[Failure] Unable to Approve Email Address"
        $outputReport.Error = $_.exception
        Return $outputReport
    } # End Approve Email Address

    # Check Email Address is Approved
    try {
        # Set Field to Query
        $getUserOptions.Fields = "emailrouteraccessapproval"

        # Get User Record
        $ApprovalStatus = Get-CrmRecords @getUserOptions -ErrorAction Stop

    }
    catch {
        Write-Output "[Failure] Unable to find User Record"
        $outputReport.Error = $_.exception
        Return $outputReport
    }

    # Initialise Counter
    $i = 0
    $Count = 30
    $Delay = 10 #seconds

    # Check whether mailflow is enabled
    while (($ApprovalStatus.CrmRecords.emailrouteraccessapproval -ne "Approved")) {

        # Step counter
        $i = $i + 1

        # Check if counter is within the limit
        if ($i -gt $Count) {
            Write-Output "[Failure] Email Address not Approved within allotted timeframe"
            $outputReport.'Address Approved' = "Not Approved"
            Return $outputReport
        }

        # Write Progress
        $progressOptions = @{
            Activity         = "Checking Email Address Approval..."
            SecondsRemaining = (($count * $delay) - ($i * $delay))
            PercentComplete  = (($i * $Delay) / ($Count * $Delay) * 100)
        } # End Progress Options

        Write-Progress @progressOptions

        # Sleep
        Start-Sleep -Seconds $Delay

        # Get results again
        $ApprovalStatus = Get-CrmRecords @getUserOptions -ErrorAction Stop

    }

    $outputReport.'Address Approved' = "Approved"
    Write-Output "[Success] Email Address Approved"

    # Get Mailbox ID
    try {
        # Set Mailbox Query Options
        $getMailboxOptions = @{
            EntityLogicalName = "mailbox"
            Fields            = "mailboxid"
            FilterAttribute   = "regardingobjectid"
            FilterOperator    = "eq"
            FilterValue       = $User.CrmRecords.systemuserid
        } # End Mailbox Query Options

        # Get Mailbox Reord
        $Mailbox = Get-CrmRecords @getMailboxOptions -ErrorAction Stop
        $outputReport.MailboxID = $Mailbox.CrmRecords.mailboxid
        Write-Output "[Success] Get Mailbox ID Record"
    }
    catch {
        Write-Output "[Failure] Unable to find Mailbox object"
        $outputReport.Error = $_.exception
        Return $outputReport
    } # End Get Mailbox ID

    # Enable Mailbox
    try {
        # Set Action Options
        $setMailboxOptions = @{
            EntityLogicalName = "mailbox"
            Id                = $Mailbox.CrmRecords.mailboxid
            Fields            = @{"testemailconfigurationscheduled" = $true}
            conn              = $Conn
            PrimaryKeyField   = "mailboxid"
        } # End Action Options

        # Set Mailbox Configuration
        Set-CrmRecord @setMailboxOptions -ErrorAction Stop
    }
    catch {
        Write-Output '[Failure] Unable to set "testemailconfigurationscheduled" on Mailbox'
        $outputReport.Error = $_.exception
        Return $outputReport
    } # End Enable Mailbox

    # Confirm Mailflow
    try {
        # Set Field to Query
        $getMailboxOptions.Fields = @("enabledforincomingemail", "enabledforoutgoingemail")

        # Get Mailbox
        $MailboxResults = Get-CrmRecords @getMailboxOptions -ErrorAction Stop
        $outputReport.'Mailflow Enabled' = "Yes"
    }
    catch {
        Write-Output "[Failure] Unable to return Mailflow options"
        $outputReport.Error = $_.exception
        Return $outputReport
    }

    # Initialise Counter
    $i = 0
    $Count = 90
    $Delay = 10 #seconds

    # Check whether mailflow is enabled
    while (($MailboxResults.CrmRecords.enabledforincomingemail -eq "No") -or `
        ($MailboxResults.CrmRecords.enabledforoutgoingemail -eq "No") ) {

        # Step counter
        $i = $i + 1

        # Check if counter is within the limit (10s x 90 = 15 minutes)
        if ($i -gt $Count) {
            Write-Output "[Failure] Mailflow not enabled within allotted timeframe"
            $outputReport.'Mailflow Enabled' = "No"
            Return $outputReport
        }

        # Write Progress
        $progressOptions = @{
            Activity         = "Checking Mailbox is Enabled..."
            SecondsRemaining = (($count * $delay) - ($i * $delay))
            PercentComplete  = (($i * $Delay) / ($Count * $Delay) * 100)
        } # End Progress Options

        Write-Progress @progressOptions

        # Sleep
        Start-Sleep -Seconds $Delay

        # Get results again
        $MailboxResults = Get-CrmRecords @getMailboxOptions -ErrorAction Stop

    }

    # Return the Reporting Object
    Write-Output "[Success] Mailbox is Enabled"
    Return $outputReport

} # End Enable-xCRMMailbox Function

foreach ($UserAddress in $UserAddresses) {
    Enable-xCRMMailbox -EmailAddress $UserAddress -CRMURL $CrmUrl -Credential $PvlCreds
}
