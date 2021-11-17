# This needs to have really good logging so that it can be put into
# a string object and sent in the body of an email






$ScriptStartTime = Get-Date

$ChangeWindow = Get-Date -Month 3 -Day 27 -Year 2020 -Hour 21 -Minute 01
$TimeToSleepUntilChangeWindow = ($ChangeWindow - (Get-Date)).TotalSeconds

# If the script is run after the desired change window, don't sleep
if ($TimeToSleepUntilChangeWindow -lt 0){
    $TimeToSleepUntilChangeWindow = 0
}
Start-Sleep -s $TimeToSleepUntilChangeWindow

# Change window opens (10pm-5am eastern is our maintenance window)
# The desired time to make the change happens
$Server = "server"
$Url = "blog.server.com"
$SysadminEmail = "admin@domain.com"
$EmailBody = ""
$ChangeStatus = ""

# See if health check passes
$PrechangeHealthCheck01 = Invoke-WebRequest $Server
$PrechangeHealthCheck02 = Invoke-WebRequest $Url

# Verify the current state of what you wish to change
$PrechangeLastBootTime = Invoke-Command -ComputerName $Server -ScriptBlock {
    $PrechangeLastBootTime = Get-CimInstance -ClassName win32_operatingsystem | Select-Object csname, lastbootuptime
}

# Make the change
# -- If making a series of changes, verify each change has been made before progressing to the next step

$InvokeCommandOutput = Invoke-Command -ComputerName $Server -ScriptBlock {
    Restart-Computer -Force
}
# Wait for the server to come back up
# TODO: Put this in a loop that occasionally tests to see if the server is back up yet; fail out after X minutes
Start-Sleep -s 180 

# See if health check passes
$PostchangeHealthCheck01 = Invoke-WebRequest $Server
$PostchangeHealthCheck02 = Invoke-WebRequest $Url

# Verify the change
$PostchangeLastBootTime = Get-CimInstance -ClassName win32_operatingsystem | Select-Object csname, lastbootuptime
if ($PrechangeLastBootTime.lastbootuptime -lt $PostchangeLastBootTime.lastbootuptime) {
    $EmailBody += "The reboot was successful. It happened at $($PostchangeLastBootTime.lastbootuptime)`n`n"    
} else {
    $EmailBody += "The reboot was not successful. Compare the following:
    Pre-change boot time: $($PrechangeLastBootTime.lastbootuptime)
    Post-change boot time: $($PostchangeLastBootTime.lastbootuptime)`n`n"
    $ChangeStatus = "[ERROR]"
}

# Evaluate healthchecks
if ($PrechangeHealthCheck01.StatusCode -eq $PostchangeHealthCheck01.StatusCode) {
    $EmailBody += "Health check 01 matches with status code $($PrechangeHealthCheck01.StatusCode)`n`n"
} else {
    $EmailBody += "Health check 01 status codes do not match. This may be expected or not. Compare the following:
    Pre-change status code: $($PrechangeHealthCheck01.StatusCode)
    Post-change status code: $($PostchangeHealthCheck01.StatusCode)`n`n"

    if ($ChangeStatus -ne "") {
        $ChangeStatus = "[WARN]"
    }
}

if ($PrechangeHealthCheck02.StatusCode -eq $PostchangeHealthCheck02.StatusCode) {
    $EmailBody += "Health check 02 matches with status code $($PrechangeHealthCheck01.StatusCode)`n`n"
} else {
    $EmailBody += "Health check 02 status codes do not match. This may be expected or not. Compare the following:
    Pre-change status code: $($PrechangeHealthCheck02.StatusCode)
    Post-change status code: $($PostchangeHealthCheck02.StatusCode)`n`n"

    if ($ChangeStatus -ne "") {
        $ChangeStatus = "[WARN]"
    }
}

# If no other status is set negatively, evaluate as successful
if ($ChangeStatus -eq "") {
    $ChangeStatus = "[TEST]" # [SUCCESS]
}
$EmailSubject = $ChangeStatus + " " + "Change Window $(Get-Date -Format 'MM-dd-yyyy HH:mm')"

$ScriptEndTime = Get-Date
$ScriptTotalTime = $ScriptEndTime - $ScriptStartTime
$EmailBody += "Script execution time (including Start-Sleep): $($ScriptTotalTime.totalMinutes) minutes`n`n"
$EmailBody += "---------------------------`n"
$EmailBody += "Invoke-Command Output`n"
$EmailBody += "---------------------------`n"
$EmailBody += $InvokeCommandOutput + "`n"

Send-MailMessage -From "ChangeWindow@domain.com" -To $SysadminEmail -SmtpServer exchange.domain.local -Subject $EmailSubject -Body $EmailBody -ReplyTo $SysadminEmail -Verbose
# Change window closes