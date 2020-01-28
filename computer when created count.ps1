$enabledComputers = Get-ADComputer -Filter {(Enabled -eq "True")} -Properties WhenCreated,operatingsystem | Sort Name

$olderThan2016 = @()
$olderThan2015 = @()

foreach ($computer in $enabledComputers) {
    if ($computer.WhenCreated -lt (Get-Date "1/1/2016 00:00:01")) {
        $olderThan2016 += $computer        
    }
    if ($computer.WhenCreated -lt (Get-Date "1/1/2015 00:00:01")) {
        $olderThan2015 += $computer        
    }
}

$olderThan2016.Count
$olderThan2015.Count