# DESCRIPTION
# area
# activity
# hrs per day, wk, mo
param (
    [ValidateScript({Test-Path $_})]
    [Parameter(Position = 0)]
    $ActivitiesFile = "activities.json"
)
#Test-Path -Path $ActivitiesFile
try {
    $Activities = loadActivities -ActivitiesFile $ActivitiesFile -Verbose
} catch {
    $Activities = @()
}


# $Activity = @{
#     Name = "Sleeping";
#     HoursWeekly = 45.5;
#     IsRestful = $false; # only conscious resting activities count
# }
# $Activities += $Activity


$HoursInAWeek = 168
$WorkRestRatio = 6/7 # 6:1
$Hours 

# save activities
function saveActivities {
    param (
        $Activities = $ActivitiesObject,
        $ActivitiesFile = $ActivitiesFile
    )
    ConvertTo-Json $Activities | Out-File $ActivitiesFile -Verbose
}
# load activities
function loadActivities {
    param (
        $ActivitiesFile = $ActivitiesFile
    )
    Write-Host "Loading file $ActivitiesFile..."
    return ConvertFrom-Json $ActivitiesFile
}

# add activity
function addActivity {
    param (
        $Activities = $Activities
    )
    
    $Activity = @{}
    $Activity.Name = Read-Host -Prompt "Name? "
    $Activity.HoursWeekly = Read-Host -Prompt "HoursWeekly? "
    $Activity.IsRestful = Read-Host -Prompt "Is this Restful? "

    $Activities += $Activity
    saveActivities -Activities $Activities

    return $Activities
}
# edit activity
# display activities
$PercentAllocated = $Activities.HoursWeekly * 100 / $HoursInAWeek
$Margin = 100 - $PercentAllocated
$HoursRemaining = $HoursInAWeek - $Activities.HoursWeekly
Write-Host "$($Activities.Count) activites accounting for $PercentAllocated"
Write-Host "$HoursRemaining hours remaining ($Margin% margin)"

addActivity