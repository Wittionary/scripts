# Enable litigation hold for users if flag is set
# Disable litigation hold for users if flag is set
# Do nothing if the action/verb is not explicit
# Let me be able to paste series of users straight from an email
# Run -whatif the first time and ask for confirmation

param(
    $Users = "Kevian Harsmon
    Jersemy Stodne
    Isdaac Rodrgiguez
    Dafve Zieglke
    Bregndan Swfift
    Heafther Nadsh
    Satadri Durrsah
    Richsie Saamay",         # One or more users that need to be put on or removed from litigation hold at the same time
    $EnableHold = $null, # If we default to $true or $false, we allow a potentially destructive action to take place
    $Delimiter = "`n"
)
# Correct invalid delimiters
# Linebreak
if (($Delimiter -contains "*break") -or ($Delimiter -contains "*line*") -or ($Delimiter -match "n") -or ($Delimiter -match "r")) {
    $Delimiter = "`n"
# Comma
} elseif (($Delimiter -contains "*comma*") -or ($Delimiter -contains "*coma*") -or ($Delimiter -contains "*,*")) {
    $Delimiter = ","
}


# Connect to O365
$UserCredential = Get-Credential -UserName "admin@domain.com" -Message "Connect to Office 365 Resources"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking




# Split into individual users
$Users = $Users.Split($Delimiter)
Write-Host "$($Users.Count) users were found."
# Sanitize input of $Users; only accept "First Last" or "Last, First" as the first two words of a line
$SanitizedUsers = @()
foreach ($User in $Users) {
    $Line = $User.Split(" ")
    $User = "$($Line[0]) $($Line[1])"
    $SanitizedUsers += $User
}

# Get the mailbox identity of each user by iterating through first name, then last name and overlapping the sets of information
$Mailboxes = @()
foreach ($SanitizedUser in $SanitizedUsers) {
    # Re-sanitize in case of wonky formatting being copied from email
    $SanitizedUser = $SanitizedUser.Trim()
    # TODO: Remove non-alphabet characters/punctuation; this will remove unintentional delimiters e.g. "Lastname, Firstname"
    # NOTE: Variable names could be misnomers as it's an assumption the information in email is formatted as "Firstname Lastname"
    # NOTE: This won't work if there's a case where information is received as "Firstname Middlename Lastname"
    $UserFirst = ($SanitizedUser.Split(" "))[0]
    $UserLast = ($SanitizedUser.Split(" "))[1]

    $MatchingFirst = Get-Mailbox "*$($UserFirst)*" | Select-Object -Property Alias
    $MatchingLast = Get-Mailbox "*$($UserLast)*" | Select-Object -Property Alias

    foreach ($First in $MatchingFirst) {
        foreach ($Last in $MatchingLast) {
            if ($Last -match $First) {
                $MatchingBoth += $Last
            }
        }
    }
}

# Return the current litigation hold status of all users
# Ask for confirmation on either enabling or disabling litigation hold on the current set of users; return the number of changes that will be made
# TODO: add hard limit on number of changes that can be made at once
# Make the changes
# Return the new status of each mailbox

# gets all users that are on a litigation hold
# return their legal name, user name, mailbox UPN, and  Exchange GUID
$HoldResults = Get-Mailbox -Filter "$_.LitigationHoldEnabled -eq 'True'" | Select-Object DisplayName,UserPrincipalName,LitigationHoldDuration,ExchangeGuid | Sort-Object -Property DisplayName

#Set-Mailbox bsuneja@contoso.com -LitigationHoldEnabled $true
