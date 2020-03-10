$UniqueIPResponses = @()
$DnsRecord = "www.twitter.com/wittionary"


for ($i=0; $i -lt 5000; $i++) {
    $UniqueIPResponses += ((tnc $DnsRecord).RemoteAddress).IPAddressToString
}

$UniqueIPResponses = $UniqueIPResponses | Sort-Object
$UniqueIPs = $UniqueIPResponses | Get-Unique

foreach ($UniqueIP in $UniqueIPs) {
    $Count = 0
    foreach ($UniqueIPResponse in $UniqueIPResponses) {
        if ($UniqueIPResponse -eq $UniqueIP) {
            $Count += 1
        }
    }
    Write-Host $UniqueIP "-" $Count
}



# 8/29/2019 7:11:00 PM