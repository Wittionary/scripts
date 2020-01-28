$win8 = Get-ADComputer -Filter {(OperatingSystem -like "*8*") -and (Enabled -eq "True")} -Properties OperatingSystem | Sort Name
$win8 | group operatingsystem